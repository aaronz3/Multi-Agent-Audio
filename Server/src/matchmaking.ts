import crypto from "crypto";
import WebSocket from 'ws';

import http from "http";
import internal from "stream";

import { rooms, roomsContainer, Room, maxNumberOfPlayers } from "./global-properties";
import { modifyRoom } from "./websocket-room";
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { AttributeValue } from "@aws-sdk/client-dynamodb";

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

	if (wss) {
		wss.handleUpgrade(request, socket, head, (incomingClient) => {
			wss.emit("connection", incomingClient, request);
		});
	} else {
		// Send an error to the client
		console.log("DEBUG: Suitable room was not found")
	}
	
	console.log(`Number of rooms: ${roomsContainer.getRoomsLength()}`);
}

// Update rooms array and return a websocket server 
export async function updateRoomReturnWebSocketServer(uuid: string): Promise<WebSocket.Server> {
	
	let userData: Record<string, AttributeValue>
	
	// Check the database to see if the user was previously in a game
	try {
		const data = await accessDB.getDataInTable("User-Data", "User-ID", uuid)
		
		// Returned data object must be defined
		if (data) {
			userData = data
		
		// If user's data is not avaliable, which should never be the case at this stage
		} else {
			throw new Error("DEBUG: User data does not exist")
		}
	// Get user data must not return an error
	} catch {
		throw new Error("DEBUG: Error in updateRoomReturnWebSocketServer getting user data")
	}

	// IF USER WAS IN A GAME 
	const previousRoomUUID = userData["Previous-Room"]?.S // The previous room string exists
	if (previousRoomUUID) {
		const room = roomsContainer.getRoom(previousRoomUUID) // The server still has a record of the room
		
		// If the room is still available, return its websocket server, else consider the room disband
		if (room) {
			return room.websocketServer
		} else {
			return await handleUserNotInGame(uuid)
		}

	// IF USER WAS NOT IN A GAME OR GAME DOES NOT EXIST
	} else {
		return await handleUserNotInGame(uuid)
	}
}

async function handleUserNotInGame(uuid: string): Promise<WebSocket.Server> {
	// If no rooms exists or all rooms are currently full
	if (roomsContainer.getRoomsLength() == 0 || roomsContainer.roomIsNotAvailable()) {
		
		return await returnNewRoom(uuid)

	// If a room exists or some room still has space
	} else {
		
		// Return the most suitable room
		const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty()

		if (suitableRoom) {
			
			// Update the Users attribute in Room-Data table
			await accessDB.updateItemsInTable("Room-Data", "Room-ID", suitableRoom.roomID, "Users", [uuid])

			return suitableRoom.websocketServer;
		
		// If for some reason no suitable room was found 
		} else {
			return await returnNewRoom(uuid)
		}
	}
}

async function returnNewRoom(uuid: string): Promise<WebSocket.Server> {
		// Create a new room
		const roomUUID = crypto.randomUUID();
		const wss = new WebSocket.Server({ noServer: true });
		const room = new Room(roomUUID, wss);

		// Modify the properties of a room instance when a user connects, sends a message, etc.
		modifyRoom(room);
		
		const putDataIntoRoom = {
			"Users": { "SS": [uuid] },
			"Host": { "S": uuid },
			"Game-State": { "S": "InLobby"}
		}

		// Update the users attribute in Room-Data table
		await accessDB.putItemInTable("Room-Data", "Room-ID", roomUUID, putDataIntoRoom)

		// Add the newly created room into the rooms array.
		roomsContainer.addRoom(room);
		
		return wss
}


// Algorithm to put the user in an available room with the most people
export function returnMostSuitableRoomAndUpdateRoomProperty(): (Room | undefined) {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom: Room | undefined;
    
	for (const room of rooms) {
		if (numberOfPlayersInPreviousRoom < room.agentUUIDConnection.size && room.agentUUIDConnection.size < maxNumberOfPlayers) {
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
  

