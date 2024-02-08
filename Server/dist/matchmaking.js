"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.handlePlay = void 0;
const global_properties_1 = require("./global-properties");
const crypto_1 = __importDefault(require("crypto"));
const ws_1 = __importDefault(require("ws"));
const modifyRoom = require("./websocket-room");
function handlePlay(request, socket, head) {
    let wss;
    // If room is empty or all rooms are currently full, create a new room
    if (global_properties_1.rooms.length == 0 || roomIsNotAvailable()) {
        const roomUUID = crypto_1.default.randomUUID();
        wss = new ws_1.default.Server({ noServer: true });
        const room = new global_properties_1.Room(roomUUID, 0, wss);
        // Modify the properties of a room instance when a user connects, sends a message, etc.
        modifyRoom(room);
        // Add the newly created room into the rooms array.
        global_properties_1.rooms.push(room);
        // Else join the room that is about to be filled.
    }
    else {
        const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty();
        if (suitableRoom) {
            wss = suitableRoom;
        }
        else {
            console.log("DEBUG: Suitable room was undefined");
        }
    }
    if (wss) {
        wss.handleUpgrade(request, socket, head, (ws) => {
            if (wss) {
                wss.emit("connection", ws, request);
            }
        });
    }
    console.log(`Number of rooms: ${global_properties_1.rooms.length}`);
}
exports.handlePlay = handlePlay;
// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
    let numberOfPlayersInPreviousRoom = 0;
    let returnRoom = undefined;
    for (const room of global_properties_1.rooms) {
        if (room.numberOfPlayers > numberOfPlayersInPreviousRoom && room.numberOfPlayers < global_properties_1.maxNumberOfPlayers) {
            numberOfPlayersInPreviousRoom = room.numberOfPlayers;
            returnRoom = room;
        }
    }
    if (returnRoom) {
        return returnRoom.websocketServer;
    }
    else {
        // Handle the case where no room is found
        console.log("DEBUG: No room found");
        return undefined; // Or throw an error, or return a default value
    }
}
// Helper function to determine if any rooms are available to join
function roomIsNotAvailable() {
    let noRoomsAvailable = true;
    for (const room of global_properties_1.rooms) {
        if (room.numberOfPlayers > 0 && room.numberOfPlayers < global_properties_1.maxNumberOfPlayers) {
            noRoomsAvailable = false;
            // Exit the loop as soon as an available room is found
            break;
        }
    }
    return noRoomsAvailable;
}
