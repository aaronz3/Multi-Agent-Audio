"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.returnMostSuitableRoomAndUpdateRoomProperty = exports.updateRoomReturnWebSocketServer = exports.handlePlay = void 0;
const global_properties_1 = require("./global-properties");
const crypto_1 = __importDefault(require("crypto"));
const ws_1 = __importDefault(require("ws"));
const websocket_room_1 = require("./websocket-room");
// Emit a connection on some websocket server when an agent connects
function handlePlay(request, socket, head) {
    const wss = updateRoomReturnWebSocketServer();
    if (wss) {
        wss.handleUpgrade(request, socket, head, (incomingClient) => {
            wss.emit("connection", incomingClient, request);
        });
    }
    else {
        console.log("DEBUG: Suitable room was not found");
    }
    console.log(`Number of rooms: ${global_properties_1.roomsContainer.getRoomsLength()}`);
}
exports.handlePlay = handlePlay;
// Update rooms array and return a websocket server 
function updateRoomReturnWebSocketServer() {
    // If room is empty or all rooms are currently full, create a new room
    if (global_properties_1.roomsContainer.getRoomsLength() == 0 || global_properties_1.roomsContainer.roomIsNotAvailable()) {
        const roomUUID = crypto_1.default.randomUUID();
        const wss = new ws_1.default.Server({ noServer: true });
        const room = new global_properties_1.Room(roomUUID, wss);
        // Modify the properties of a room instance when a user connects, sends a message, etc.
        (0, websocket_room_1.modifyRoom)(room);
        // Add the newly created room into the rooms array.
        global_properties_1.roomsContainer.addRoom(room);
        return wss;
        // Else join the room that is about to be filled.
    }
    else {
        const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty();
        if (suitableRoom) {
            return suitableRoom;
        }
        else {
            return undefined;
        }
    }
}
exports.updateRoomReturnWebSocketServer = updateRoomReturnWebSocketServer;
// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
    let numberOfPlayersInPreviousRoom = 0;
    let returnRoom;
    for (const room of global_properties_1.rooms) {
        if (room.agentUUIDConnection.size > numberOfPlayersInPreviousRoom && room.agentUUIDConnection.size < global_properties_1.maxNumberOfPlayers) {
            numberOfPlayersInPreviousRoom = room.agentUUIDConnection.size;
            returnRoom = room;
        }
    }
    if (returnRoom) {
        return returnRoom.websocketServer;
    }
    else {
        return undefined;
    }
}
exports.returnMostSuitableRoomAndUpdateRoomProperty = returnMostSuitableRoomAndUpdateRoomProperty;
