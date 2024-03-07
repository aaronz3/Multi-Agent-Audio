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
export async function updateRoomReturnWebSocketServer(uuid: string): Promise<WebSocket.Server | undefined> {
	
	let userData: Record<string, AttributeValue>
	
	// Check the database to see if the user was previously in a game
	try {
		const data = await accessDB.getUserData(uuid)
		
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
	if (userData["Previous-Room"]?.S !== undefined) {
		const previousRoom = userData["Previous-Room"]?.S!
		const room = roomsContainer.getRoom(previousRoom)
		
		// If the room is still available, return its websocket server, else consider the room disband
		return (room != undefined ? room.websocketServer : handleUserNotInGame())

	// IF USER WAS NOT IN A GAME OR GAME DOES NOT EXIST
	} else {
		return handleUserNotInGame()
	}
}

function handleUserNotInGame(): WebSocket.Server | undefined {
	// If no rooms exists or all rooms are currently full, create a new room
	if (roomsContainer.getRoomsLength() == 0 || roomsContainer.roomIsNotAvailable()) {

		const roomUUID = crypto.randomUUID();
		const wss = new WebSocket.Server({ noServer: true });
		const room = new Room(roomUUID, wss);

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
			return undefined
		}
	}
}


// Algorithm to put the user in an available room with the most people
export function returnMostSuitableRoomAndUpdateRoomProperty(): (WebSocket.Server | undefined) {
	let numberOfPlayersInPreviousRoom = 0;
	let returnRoom: Room | undefined;
    
	for (const room of rooms) {
		if (room.agentUUIDConnection.size > numberOfPlayersInPreviousRoom && room.agentUUIDConnection.size < maxNumberOfPlayers) {
			numberOfPlayersInPreviousRoom = room.agentUUIDConnection.size;
			returnRoom = room;
		}
	}

	if (returnRoom) {
        return returnRoom.websocketServer;
    } else {
        return undefined; 
    }
}
  

