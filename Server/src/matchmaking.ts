import { rooms, Room, maxNumberOfPlayers } from "./global-properties";
import crypto from "crypto";
import WebSocket from 'ws';

import http from "http";
import internal from "stream";

const modifyRoom = require("./websocket-room");

export function handlePlay(request: http.IncomingMessage, socket: internal.Duplex, head: Buffer) {
	let wss: (WebSocket.Server | undefined); 

	// If room is empty or all rooms are currently full, create a new room
	if (rooms.length == 0 || roomIsNotAvailable()) {
		const roomUUID = crypto.randomUUID();
		wss = new WebSocket.Server({ noServer: true });
      
		const room = new Room(roomUUID, 0, wss);

		// Modify the properties of a room instance when a user connects, sends a message, etc.
		modifyRoom(room);
      
		// Add the newly created room into the rooms array.
		rooms.push(room);

	// Else join the room that is about to be filled.
	} else {
		const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty()
		if (suitableRoom) {
			wss = suitableRoom;
		} else {
			console.log("DEBUG: Suitable room was undefined")
		}
		
	}
	
	if (wss) {
		wss.handleUpgrade(request, socket, head, (ws) => {
			if (wss) {
				wss.emit("connection", ws, request);
			}
		});
	}
	
	console.log(`Number of rooms: ${rooms.length}`);
}

// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty(): (WebSocket.Server | undefined) {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom: Room | undefined = undefined;
    
	for (const room of rooms) {
		if (room.numberOfPlayers > numberOfPlayersInPreviousRoom && room.numberOfPlayers < maxNumberOfPlayers) {
			numberOfPlayersInPreviousRoom = room.numberOfPlayers;
			returnRoom = room;
		}
	}

	if (returnRoom) {
        return returnRoom.websocketServer;
    } else {
        // Handle the case where no room is found
		console.log("DEBUG: No room found")
        return undefined; // Or throw an error, or return a default value
    }
}
  
// Helper function to determine if any rooms are available to join
function roomIsNotAvailable(): boolean {
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