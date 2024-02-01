// Room Data
const rooms = [];

// Configuration
const maxNumberOfPlayers = 2;

// Structure of an instance of a room will be as follows 
class Room {
    constructor(roomID, numberOfPlayers, agentUUIDConnection, websocketServer) {
        this.roomID = roomID
        this.numberOfPlayers = numberOfPlayers        
        this.agentUUIDConnection = agentUUIDConnection
        this.websocketServer = websocketServer
    }
} 

module.exports = {rooms, maxNumberOfPlayers, Room}