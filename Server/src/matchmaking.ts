import { rooms, roomsContainer, Room, maxNumberOfPlayers } from "./global-properties";
import crypto from "crypto";
import WebSocket from 'ws';

import http from "http";
import internal from "stream";

import { modifyRoom } from "./websocket-room";

// Emit a connection on some websocket server when an agent connects
export function handlePlay(request: http.IncomingMessage, socket: internal.Duplex, head: Buffer) {
	
	const wss = updateRoomReturnWebSocketServer()

	if (wss) {
		wss.handleUpgrade(request, socket, head, (incomingClient) => {
			wss.emit("connection", incomingClient, request);
		});
	} else {
		console.log("DEBUG: wss undefined")
	}
	
	console.log(`Number of rooms: ${roomsContainer.getRoomsLength()}`);
}

// Update rooms array and return a websocket server 
export function updateRoomReturnWebSocketServer(): ( WebSocket.Server | undefined ) {
	 
	// If room is empty or all rooms are currently full, create a new room
	if (roomsContainer.getRoomsLength() == 0 || roomsContainer.roomIsNotAvailable()) {

		const roomUUID = crypto.randomUUID();
		const wss = new WebSocket.Server({ noServer: true });
      
		const room = new Room(roomUUID, 0, wss);

		// Modify the properties of a room instance when a user connects, sends a message, etc.
		modifyRoom(room);
      
		// Add the newly created room into the rooms array.
		roomsContainer.addRoom(room);
		
		return wss

	// Else join the room that is about to be filled.
	} else {
		const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty()
		if (suitableRoom) {
			return suitableRoom;
		} else {
			console.log("DEBUG: Suitable room was not found")
			return undefined
		}
	}
}

// Algorithm to put the user in an available room with the most people
export function returnMostSuitableRoomAndUpdateRoomProperty(): (WebSocket.Server | undefined) {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom: Room | undefined;
    
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
  

