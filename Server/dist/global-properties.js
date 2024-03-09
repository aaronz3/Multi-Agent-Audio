"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCurrentTime = exports.Room = exports.maxNumberOfPlayers = exports.roomsContainer = exports.rooms = void 0;
// Room Data
exports.rooms = [];
// TODO:
exports.roomsContainer = {
    addRoom: (room) => { exports.rooms.push(room); },
    setRooms: (newRooms) => { exports.rooms = newRooms; },
    getRoomsLength: () => { return exports.rooms.length; },
    // Helper function to get a room given the room id
    getRoom: (roomUUID) => {
        for (const room of exports.rooms) {
            if (room.roomID === roomUUID) {
                return room;
            }
        }
        return undefined;
    },
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
            if (0 < room.agentUUIDConnection.size && room.agentUUIDConnection.size < exports.maxNumberOfPlayers) {
                noRoomsAvailable = false;
                // Exit the loop as soon as an available room is found
                break;
            }
        }
        return noRoomsAvailable;
    }
};
// Every room can only have these many players
exports.maxNumberOfPlayers = 2;
// Structure of an instance of a room will be as follows 
class Room {
    constructor(roomID, websocketServer) {
        this.gameState = "InLobby";
        this.agentUUIDConnection = new Map();
        this.clientIsAliveMap = new Map();
        this.roomID = roomID;
        this.websocketServer = websocketServer;
    }
}
exports.Room = Room;
// For debugging purposes print the current time of events
const getCurrentTime = () => {
    const now = new Date(); // Create a new date object with the current date and time
    // Extract the day, hour, minute, and second
    const month = now.getMonth() + 1; // Month
    const day = now.getDate(); // Day of the month
    const year = now.getFullYear(); // Year
    const hour = now.getHours(); // Hour (0-23)
    const minute = now.getMinutes(); // Minute (0-59)
    const second = now.getSeconds(); // Second (0-59)
    // Return the time components
    return `[DAY: ${month}-${day}-${year}. TIME: ${hour}:${minute}:${second}]`;
};
exports.getCurrentTime = getCurrentTime;
