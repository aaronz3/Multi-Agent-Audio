"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deleteKeyValuePairAndReturnKey = exports.handleWSClosure = exports.receivedJustConnectedUser = exports.modifyRoom = void 0;
const ws_1 = __importDefault(require("ws"));
const global_properties_1 = require("./global-properties");
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
        // Handle message
        incomingClient.on("message", (message) => {
            // Ensure message is treated as a string regardless of its original type
            let messageAsString;
            if (Buffer.isBuffer(message)) {
                messageAsString = message.toString();
            }
            else {
                console.log(`DEBUG: Unhandled message type ${message}`);
                return;
            }
            handleWSMessage(room, messageAsString, incomingClient);
        });
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
    try {
        const parsedMessage = JSON.parse(message);
        switch (parsedMessage.type) {
            case "JustConnectedUser":
                // This is the current user's UUID
                const incomingClientUUID = parsedMessage.payload["userUUID"];
                receivedJustConnectedUser(room, Buffer.from(message), incomingClient, incomingClientUUID);
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
                console.log("Unknown message type:", parsedMessage.type);
        }
    }
    catch (error) {
        console.error("Error parsing message:", error);
    }
}
// SECTION: RECEVIED MESSAGE TYPES
// -----------------------
function receivedJustConnectedUser(room, message, incomingClient, incomingClientUUID) {
    // If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance.
    // The is important for when a user disconnects from the internet and reconnects to the internet and to the server.
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
    // Send the room id to the agent that connected
    const roomID = JSON.stringify({ type: "RoomCharacteristics", payload: { roomID: room.roomID } });
    sendTo(room, incomingClientUUID, Buffer.from(roomID));
}
exports.receivedJustConnectedUser = receivedJustConnectedUser;
// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------
function sendToAllButSelf(room, message, incomingClient, incomingClientUUID) {
    // The agent must belong in room.agentUUIDConnection
    room.agentUUIDConnection.forEach((client) => {
        if (client !== incomingClient && client.readyState === ws_1.default.OPEN) {
            client.send(message);
            console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
        }
    });
}
function sendTo(room, agent, message) {
    // The agent must belong in room.agentUUIDConnection
    room.agentUUIDConnection.forEach((client) => {
        if (client === room.agentUUIDConnection.get(agent) && client.readyState === ws_1.default.OPEN) {
            client.send(message);
        }
    });
}
// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------
function handleWSClosure(room, incomingClient) {
    const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient);
    if (disconnectedUserUUID === undefined) {
        console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);
    }
    else {
        console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
        console.log(`${(0, global_properties_1.getCurrentTime)()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);
        // Let the other agents know that an user has disconnected from the server
        const disconnectionUserMessage = JSON.stringify({ type: "DisconnectedUser", payload: { userUUID: disconnectedUserUUID } });
        sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);
    }
    if (room.agentUUIDConnection.size == 0) {
        // Handle deleting the room here. If the room does not exist, no errors are thrown
        global_properties_1.roomsContainer.deleteRoomFromRooms(room);
    }
}
exports.handleWSClosure = handleWSClosure;
// Helper function to delete the user that left the room
function deleteKeyValuePairAndReturnKey(obj, targetValue) {
    for (const [key, value] of obj.entries()) {
        if (value === targetValue) {
            // Delete the matching entry
            obj.delete(key);
            // Immediately return the key. 
            return key;
        }
    }
    return undefined; // Return undefined if no matching value is found
}
exports.deleteKeyValuePairAndReturnKey = deleteKeyValuePairAndReturnKey;
