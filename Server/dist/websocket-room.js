"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteKeyValuePairAndReturnKey = exports.handleWSClosure = exports.receivedJustConnectedUser = exports.modifyRoom = void 0;
const ws_1 = __importDefault(require("ws"));
const global_properties_1 = require("./global-properties");
const access_dynamodb_1 = require("./access-dynamodb");
require("dotenv").config({ path: '../.env' });
const databaseRegion = process.env.DYNAMODB_BUCKET_REGION;
const accessDB = new access_dynamodb_1.AccessUserDataDynamoDB(databaseRegion);
// SECTION: MODIFY ROOM PROPERTIES
// -----------------------
// Update agentUUIDConnection of room
function modifyRoom(room) {
    // Create a Map to track the 'isAlive' property for each client
    const wss = room.websocketServer;
    wss.on("connection", (incomingClient, req) => {
        console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] Client connected from IP: ${req.socket.remoteAddress}. Total connected clients: ${wss.clients.size}.`);
        // Initialize the 'isAlive' property for the new client
        room.clientIsAliveMap.set(incomingClient, true);
        // Send the message to other users
        incomingClient.on("message", (message) => __awaiter(this, void 0, void 0, function* () {
            // Ensure message is treated as a string regardless of its original type
            let messageAsString;
            if (Buffer.isBuffer(message)) {
                messageAsString = message.toString();
            }
            else {
                console.log(`DEBUG: Unhandled message type ${message}`);
                return;
            }
            yield handleWSMessage(room, messageAsString, incomingClient);
        }));
        // Handle websocket closure
        incomingClient.on("close", () => {
            handleWSClosure(room, incomingClient);
        });
        // Set up pong response listener
        incomingClient.on("pong", () => {
            // Mark client as alive upon receiving a pong
            room.clientIsAliveMap.set(incomingClient, true);
        });
        incomingClient.on('error', (error) => {
            console.log(`DEBUG: An error occurred with the WebSocket: ${error.message}`);
        });
    });
    // This is useful for dropping agents that have disconnected the websocket connection but are unable to let the server know.
    function heartbeat() {
        wss.clients.forEach((ws) => {
            if (room.clientIsAliveMap.get(ws) === false) {
                try {
                    ws.terminate();
                }
                catch (e) {
                    console.log(`DEBUG: Could not terminate connection. Error: ${e}`);
                }
                return;
            }
            room.clientIsAliveMap.set(ws, false);
            ws.ping();
        });
    }
    setInterval(heartbeat, 10000);
}
exports.modifyRoom = modifyRoom;
// SECTION: HANDLE WEBSOCKET MESSAGE EVENT
// -----------------------
function handleWSMessage(room, message, incomingClient) {
    return __awaiter(this, void 0, void 0, function* () {
        try {
            const parsedMessage = JSON.parse(message);
            switch (parsedMessage.type) {
                case "StartGame":
                    yield receivedStartGame(room);
                    break;
                case "EndGame":
                    yield receivedEndGame(room);
                    break;
                case "DisconnectedUser":
                    const disconnectingClientUUID = parsedMessage.payload["userUUID"];
                    yield receivedLeaveGame(room, incomingClient, disconnectingClientUUID);
                    break;
                case "JustConnectedUser":
                    const connectingClientUUID = parsedMessage.payload["userUUID"];
                    yield receivedJustConnectedUser(room, Buffer.from(message), incomingClient, connectingClientUUID);
                    break;
                case "SessionDescription":
                    const forwardingAddressForSDP = parsedMessage.payload["toUUID"];
                    console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] Sent SDP to ${forwardingAddressForSDP}`);
                    sendTo(room, forwardingAddressForSDP, Buffer.from(message));
                    break;
                case "IceCandidate":
                    const forwardingAddressForICECandidate = parsedMessage.payload["toUUID"];
                    console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] Sent candidate to ${forwardingAddressForICECandidate}`);
                    sendTo(room, forwardingAddressForICECandidate, Buffer.from(message));
                    break;
                default:
                    console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] Unknown message type: ${parsedMessage.type}`);
            }
        }
        catch (error) {
            console.error("Error parsing message:", error);
        }
    });
}
// SECTION: RECEVIED MESSAGE TYPES
// -----------------------
function receivedLeaveGame(room, incomingClient, incomingClientUUID) {
    return __awaiter(this, void 0, void 0, function* () {
        // Other clients should know about a user leaving the game
        handleWSClosure(room, incomingClient);
        // Delete the previous room attribute so that the user doesn't reconnect to the previous room
        yield accessDB.deleteItemInColumnInTable("User-Data", "User-ID", incomingClientUUID, "Previous-Room");
        // // Only access the database if the user leaves during a game
        // if (room.gameState === "InGame") {
        // }
    });
}
function receivedEndGame(room) {
    return __awaiter(this, void 0, void 0, function* () {
        // Delete the previous room entry in User-Data for all users in the room.
        // This allows users to join other rooms when they leave since the game has terminated.
        for (const user of room.agentUUIDConnection.keys()) {
            yield accessDB.deleteItemInColumnInTable("User-Data", "User-ID", user, "Previous-Room");
        }
        // Set the game state of the room
        room.gameState = "InLobby";
        // Let all users know that the game has ended
        const endMessage = JSON.stringify({ type: "EndGame" });
        sendToAll(room, Buffer.from(endMessage));
    });
}
function receivedStartGame(room) {
    return __awaiter(this, void 0, void 0, function* () {
        // If the number of users in the room is not enough to start the game
        if (room.agentUUIDConnection.size < global_properties_1.maxNumberOfPlayers) {
            // Let the host know why they can't start the game
            const errorMessage = JSON.stringify({ type: "StartGameResult", payload: { result: "Player count not met" } });
            sendTo(room, room.host, Buffer.from(errorMessage));
            throw new Error("NOTE: Number of players in room is not enough to start a game");
        }
        // Update the previous room attribute of each player
        for (const user of room.agentUUIDConnection.keys()) {
            yield accessDB.updateItemInTable("User-Data", "User-ID", user, "Previous-Room", room.roomID);
        }
        // Set the game state of the room
        room.gameState = "InGame";
        // Let the host know that they successfully started the game
        const successMessage = JSON.stringify({ type: "StartGameResult", payload: { result: "Success" } });
        sendTo(room, room.host, Buffer.from(successMessage));
        // Let all users know that the game is starting
        const startMessage = JSON.stringify({ type: "StartGame" });
        sendToAll(room, Buffer.from(startMessage), room.host);
    });
}
function receivedJustConnectedUser(room, message, incomingClient, incomingClientUUID) {
    return __awaiter(this, void 0, void 0, function* () {
        // If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance.
        // This is important for when a user disconnects from the internet and reconnects to the internet and to the server.
        if (room.agentUUIDConnection.has(incomingClientUUID)) {
            const agentWebsocket = room.agentUUIDConnection.get(incomingClientUUID);
            handleWSClosure(room, agentWebsocket);
            console.log(`NOTE: Deleted ${incomingClientUUID} client from room.agentUUIDConnection.`);
        }
        // Save current user's UUID into a dictionary on the server
        room.agentUUIDConnection.set(incomingClientUUID, incomingClient);
        console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);
        // Send the agent's UUID to agents that previously connected
        sendToAllButSelf(room, message, incomingClient, incomingClientUUID);
        // Send data back to the connecting user
        const sendRoomData = {
            roomID: room.roomID,
            hostUUID: room.host,
            gameState: room.gameState
        };
        // Send the status of the room to the connecting user
        const roomID = JSON.stringify({ type: "RoomCharacteristics", payload: sendRoomData });
        sendTo(room, incomingClientUUID, Buffer.from(roomID));
    });
}
exports.receivedJustConnectedUser = receivedJustConnectedUser;
// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------
function sendToAll(room, message, incomingClientUUID) {
    // The agent must belong in room.agentUUIDConnection
    room.agentUUIDConnection.forEach((client) => {
        if (client) {
            client.send(message);
        }
        // console.log(`${getCurrentTime()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
    });
}
function sendToAllButSelf(room, message, incomingClient, incomingClientUUID) {
    // The agent must belong in room.agentUUIDConnection
    room.agentUUIDConnection.forEach((client) => {
        if (client && client !== incomingClient && client.readyState === ws_1.default.OPEN) {
            client.send(message);
            // console.log(`${getCurrentTime()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
        }
    });
}
function sendTo(room, agent, message) {
    // The agent must belong in room.agentUUIDConnection
    room.agentUUIDConnection.forEach((client) => {
        if (client && client === room.agentUUIDConnection.get(agent) && client.readyState === ws_1.default.OPEN) {
            client.send(message);
        }
    });
}
// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------
// (1) Tell other users that a user is disconnecting (2) Delete the user from the room
function handleWSClosure(room, incomingClient) {
    return __awaiter(this, void 0, void 0, function* () {
        // Given the websocket client and the room, return the UUID of the disconnected user.
        const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient);
        // If the uuid exists within the room
        if (disconnectedUserUUID) {
            console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
            console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);
            // Create a payload to send to other users
            let disconnectedMessagePayload;
            // If the host has disconnected
            if (disconnectedUserUUID === room.host) {
                // Find a user that is not the host
                for (const user of room.agentUUIDConnection.keys()) {
                    if (user !== disconnectedUserUUID) {
                        disconnectedMessagePayload = { userUUID: disconnectedUserUUID, newHost: user };
                        // Update the host to some user
                        room.host = user;
                        break;
                    }
                }
            }
            else {
                disconnectedMessagePayload = { userUUID: disconnectedUserUUID };
            }
            // Let the other agents know that an user has disconnected from the server
            const disconnectionUserMessage = JSON.stringify({ type: "DisconnectedUser", payload: disconnectedMessagePayload });
            sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);
            // If the uuid does not exist within the room
        }
        else {
            console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);
        }
        if (room.agentUUIDConnection.size === 0) {
            // Handle deleting the room here. If the room does not exist, no errors are thrown
            global_properties_1.roomsContainer.deleteRoomFromRooms(room);
        }
    });
}
exports.handleWSClosure = handleWSClosure;
// Helper function to delete the user that left the room
function deleteKeyValuePairAndReturnKey(obj, targetValue) {
    for (const [key, value] of obj.entries()) {
        if (value && value === targetValue) {
            // Delete the matching entry
            obj.delete(key);
            // Immediately return the key. 
            return key;
        }
    }
    return undefined; // Return undefined if no matching value is found
}
exports.deleteKeyValuePairAndReturnKey = deleteKeyValuePairAndReturnKey;
