"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Room = exports.maxNumberOfPlayers = exports.rooms = void 0;
// Room Data
exports.rooms = [];
// Configuration
exports.maxNumberOfPlayers = 6;
// Structure of an instance of a room will be as follows 
class Room {
    constructor(roomID, numberOfPlayers, websocketServer) {
        this.agentUUIDConnection = {};
        this.roomID = roomID;
        this.numberOfPlayers = numberOfPlayers;
        this.websocketServer = websocketServer;
    }
}
exports.Room = Room;
