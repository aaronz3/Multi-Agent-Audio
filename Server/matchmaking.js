const { rooms, Room, maxNumberOfPlayers } = require("./global-properties");
const crypto = require("crypto");
const WebSocket = require("ws");

const modifyRoom = require("./websocket-room");

function handlePlay(request, socket, head) {
	let wss; 

	// If room is empty or all rooms are currently full, create a new room
	if (rooms.length == 0 || roomIsNotAvailable()) {
		const roomUUID = crypto.randomUUID();
		wss = new WebSocket.Server({ noServer: true });
      
		const room = new Room(roomUUID, 0, [], wss);

		// Modify the properties of a room instance when a user connects, sends a message, etc.
		modifyRoom(room);
      
		// Add the newly created room into the rooms array.
		rooms.push(room);

		// Else join the room that is about to be filled.
	} else {
		wss = returnMostSuitableRoomAndUpdateRoomProperty();
	}

	wss.handleUpgrade(request, socket, head, (ws) => {
		wss.emit("connection", ws, request);
	});
    
	console.log(`Number of rooms: ${rooms.length}`);
}

// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom;
    
	for (const room of rooms) {
		if (room.numberOfPlayers > numberOfPlayersInPreviousRoom && room.numberOfPlayers < maxNumberOfPlayers) {
			numberOfPlayersInPreviousRoom = room.numberOfPlayers;
			returnRoom = room;
		}
	}
  
	return returnRoom.websocketServer;
}
  
// Helper function to determine if any rooms are available to join
function roomIsNotAvailable() {
	let noRoomsAvailable = true;
	for (const room of rooms) {
		if (room.numberOfPlayers > 0 && room.numberOfPlayers < maxNumberOfPlayers) {
			noRoomsAvailable = false;
			// Exit the loop as soon as an available room is found
			break;  
		}
	}
    
	return noRoomsAvailable;
}

module.exports = {handlePlay};