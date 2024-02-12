"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Room = exports.maxNumberOfPlayers = exports.roomsContainer = exports.rooms = void 0;
// Room Data
exports.rooms = [];
// TODO:
exports.roomsContainer = {
    addRoom: (room) => { exports.rooms.push(room); },
    setRooms: (newRooms) => { exports.rooms = newRooms; },
    getRoomsLength: () => { return exports.rooms.length; },
    // Helper function to delete the room from the global rooms array if there are no players in the room
    deleteRoomFromRooms: (roomToRemove) => {
        // Find the index of the room to remove
        const index = exports.rooms.findIndex(room => room === roomToRemove);
        // If the room is found in the array, remove it
        if (index !== -1) {
            exports.rooms.splice(index, 1);
        }
        console.log(`Number of rooms: ${exports.rooms.length}`);
    },
    // Helper function to determine if any rooms are available to join
    roomIsNotAvailable: () => {
        let noRoomsAvailable = true;
        for (const room of exports.rooms) {
            if (room.numberOfPlayers > 0 && room.numberOfPlayers < exports.maxNumberOfPlayers) {
                noRoomsAvailable = false;
                // Exit the loop as soon as an available room is found
                break;
            }
        }
        return noRoomsAvailable;
    }
};
// Every room can only have these many players
exports.maxNumberOfPlayers = 6;
// Structure of an instance of a room will be as follows 
class Room {
    constructor(roomID, numberOfPlayers, websocketServer) {
        this.agentUUIDConnection = {};
        this.clientIsAliveMap = new Map();
        this.roomID = roomID;
        this.numberOfPlayers = numberOfPlayers;
        this.websocketServer = websocketServer;
    }
}
exports.Room = Room;
