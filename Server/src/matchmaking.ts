import crypto from "crypto";
import WebSocket from 'ws';

import http from "http";
import internal from "stream";

import { rooms, roomsContainer, Room, maxNumberOfPlayers } from "./global-properties";
import { modifyRoom } from "./websocket-room";
import { AccessUserDataDynamoDB } from "./access-dynamodb";

require("dotenv").config({ path: '../.env' });
const databaseRegion = process.env.DYNAMODB_BUCKET_REGION!;

const accessDB = new AccessUserDataDynamoDB(databaseRegion)

// Emit a connection on some websocket server when an agent connects
export async function handlePlay(request: http.IncomingMessage, socket: internal.Duplex, head: Buffer, url: URL) {

	let userUUID: string;

	// Get user uuid for matchmaking purposes
	if (url.searchParams.get('uuid') === null) {
		// Handle the absence of uuid
		console.log("DEBUG: uuid was undefined")
		return
	} else {
		userUUID = url.searchParams.get('uuid') as string;
	}

	const wss = await updateRoomReturnWebSocketServer(userUUID)

	wss.handleUpgrade(request, socket, head, (incomingClient) => {
		wss.emit("connection", incomingClient, request);
	});

	console.log(`Number of rooms: ${roomsContainer.getRoomsLength()}`);
}

// Update rooms array and return a websocket server 
export async function updateRoomReturnWebSocketServer(uuid: string): Promise<WebSocket.Server> {

	const userData = await accessDB.getDataInTable("User-Data", "User-ID", uuid)
	const previousRoomUUID = userData["Previous-Room"]?.S // The previous room string exists

	// IF USER WAS NOT IN A GAME OR GAME DOES NOT EXIST
	if (previousRoomUUID === undefined) {
		return handleUserNotInGame(uuid)
	}

	// IF USER WAS IN A GAME 
	const room = roomsContainer.getRoom(previousRoomUUID) // The server still has a record of the room

	// If the room is still available, return its websocket server, else consider the room disband
	if (room) {
		// Add the user to the room
		room.agentUUIDConnection.set(uuid, undefined)

		return room.websocketServer
	} else {
		return handleUserNotInGame(uuid)
	}
}

function handleUserNotInGame(uuid: string): WebSocket.Server {
	
	// If a room exists or some room still has space, return the most suitable room
	const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty()
	
	if (suitableRoom) {
		// Add the user to the room 
		suitableRoom.agentUUIDConnection.set(uuid, undefined)
		
		// Return the room
		return suitableRoom.websocketServer;

	// If for some reason no suitable room was found 
	} else {
		return returnNewRoom(uuid)
	}
}

function returnNewRoom(uuid: string): WebSocket.Server {
	// Create a new room
	const roomUUID = crypto.randomUUID();
	const wss = new WebSocket.Server({ noServer: true });
	const room = new Room(roomUUID, wss, uuid);
	
	// Modify the properties of a room instance when a user connects, sends a message, etc.
	modifyRoom(room);

	// Add the newly created room into the rooms array.
	roomsContainer.addRoom(room);

	return wss
}


// Algorithm to put the user in an available room with the most people
export function returnMostSuitableRoomAndUpdateRoomProperty(): (Room | undefined) {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom: Room | undefined;

	for (const room of rooms) {
		if (numberOfPlayersInPreviousRoom < room.agentUUIDConnection.size
			&& room.agentUUIDConnection.size < maxNumberOfPlayers
			&& room.gameState === "InLobby") {
			numberOfPlayersInPreviousRoom = room.agentUUIDConnection.size;
			returnRoom = room;
		}
	}

	if (returnRoom) {
		return returnRoom;
	} else {
		return undefined;
	}
}


