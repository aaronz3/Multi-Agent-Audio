import WebSocket from "ws";
import { roomsContainer, getCurrentTime, Room, Message, maxNumberOfPlayers } from "./global-properties";
import { IncomingMessage } from "http";
import { AccessUserDataDynamoDB } from "./access-dynamodb";
import { send } from "process";
import { json } from "stream/consumers";

require("dotenv").config({ path: '../.env' });
const databaseRegion = process.env.DYNAMODB_BUCKET_REGION!;

const accessDB = new AccessUserDataDynamoDB(databaseRegion)

// SECTION: MODIFY ROOM PROPERTIES
// -----------------------

// Update agentUUIDConnection of room
export function modifyRoom(room: Room) {
	// Create a Map to track the 'isAlive' property for each client

	const wss: WebSocket.Server = room.websocketServer;
	wss.on("connection", (incomingClient: WebSocket, req: IncomingMessage) => {

		console.log(`${getCurrentTime()} [Room ${room.roomID}] Client connected from IP: ${req.socket.remoteAddress}. Total connected clients: ${wss.clients.size}.`);

		// Initialize the 'isAlive' property for the new client
		room.clientIsAliveMap.set(incomingClient, true);

		// Send the message to other users
		incomingClient.on("message", async (message) => {

			// Ensure message is treated as a string regardless of its original type
			let messageAsString: string;
			if (Buffer.isBuffer(message)) {
				messageAsString = message.toString();
			} else {
				console.log(`DEBUG: Unhandled message type ${message}`);
				return;
			}

			await handleWSMessage(room, messageAsString, incomingClient);
		});

		// Handle websocket closure
		incomingClient.on("close", () => {
			handleWSClosure(room, incomingClient);
		});

		// Set up pong response listener
		incomingClient.on("pong", () => {
			// Mark client as alive upon receiving a pong
			room.clientIsAliveMap.set(incomingClient, true);
		});

		incomingClient.on('error', (error) => {
			console.log(`DEBUG: An error occurred with the WebSocket: ${error.message}`);
		});
	});

	// This is useful for dropping agents that have disconnected the websocket connection but are unable to let the server know.
	function heartbeat() {
		wss.clients.forEach((ws) => {
			if (room.clientIsAliveMap.get(ws) === false) {
				try {
					ws.terminate();
				} catch (e) {
					console.log(`DEBUG: Could not terminate connection. Error: ${e}`)
				}
				return
			}

			room.clientIsAliveMap.set(ws, false);
			ws.ping();
		});
	}

	setInterval(heartbeat, 10000);
}


// SECTION: HANDLE WEBSOCKET MESSAGE EVENT
// -----------------------

async function handleWSMessage(room: Room, message: string, incomingClient: WebSocket) {
	try {
		const parsedMessage: Message = JSON.parse(message);

		switch (parsedMessage.type) {

			case "StartGame":
				await receivedStartGame(room)
				break;

			case "EndGame":
				await receivedEndGame(room)
				break;

			case "DisconnectedUser":
				const disconnectingClientUUID: string = parsedMessage.payload["userUUID"];
				await receivedLeaveGame(room, incomingClient, disconnectingClientUUID)
				break;

			case "JustConnectedUser":
				const connectingClientUUID: string = parsedMessage.payload["userUUID"];
				await receivedJustConnectedUser(room, Buffer.from(message), incomingClient, connectingClientUUID);
				break;

			case "SessionDescription":
				const forwardingAddressForSDP: string = parsedMessage.payload["toUUID"];
				console.log(`${getCurrentTime()} [Room ${room.roomID}] Sent SDP to ${forwardingAddressForSDP}`);
				sendTo(room, forwardingAddressForSDP, Buffer.from(message));
				break;

			case "IceCandidate":
				const forwardingAddressForICECandidate: string = parsedMessage.payload["toUUID"];
				console.log(`${getCurrentTime()} [Room ${room.roomID}] Sent candidate to ${forwardingAddressForICECandidate}`);
				sendTo(room, forwardingAddressForICECandidate, Buffer.from(message));
				break;

			default:
				console.log(`${getCurrentTime()} [Room ${room.roomID}] Unknown message type: ${parsedMessage.type}`);
		}

	} catch (error) {
		console.error("Error parsing message:", error);
	}
}

// SECTION: RECEVIED MESSAGE TYPES
// -----------------------
async function receivedLeaveGame(room: Room, incomingClient: WebSocket, incomingClientUUID: string) {

	// Other clients should know about a user leaving the game
	handleWSClosure(room, incomingClient)
	
	// Delete the previous room attribute so that the user doesn't reconnect to the previous room
	await accessDB.deleteItemInColumnInTable("User-Data", "User-ID", incomingClientUUID, "Previous-Room")

	// // Only access the database if the user leaves during a game
	// if (room.gameState === "InGame") {
		
	// }
}

async function receivedEndGame(room: Room) {

	// Delete the previous room entry in User-Data for all users in the room.
	// This allows users to join other rooms when they leave since the game has terminated.
	for (const user of room.agentUUIDConnection.keys()) {
		await accessDB.deleteItemInColumnInTable("User-Data", "User-ID", user, "Previous-Room")
	}

	// Set the game state of the room
	room.gameState = "InLobby"

	// Let all users know that the game has ended
	const endMessage: string = JSON.stringify({ type: "EndGame" })
	sendToAll(room, Buffer.from(endMessage))
}

async function receivedStartGame(room: Room) {

	// If the number of users in the room is not enough to start the game
	if (room.agentUUIDConnection.size < maxNumberOfPlayers) {
		
		// Let the host know why they can't start the game
		const errorMessage =  JSON.stringify({ type: "StartGameResult", payload: {result: "Player count not met"} }) 
		sendTo(room, room.host, Buffer.from(errorMessage))

		throw new Error("NOTE: Number of players in room is not enough to start a game")
	}

	// Update the previous room attribute of each player
	for (const user of room.agentUUIDConnection.keys()) {
		await accessDB.updateItemInTable("User-Data", "User-ID", user, "Previous-Room", room.roomID)
	}

	// Set the game state of the room
	room.gameState = "InGame"

	// Let the host know that they successfully started the game
	const errorMessage =  JSON.stringify({ type: "StartGameResult", payload: {result: "Success"} }) 
	sendTo(room, room.host, Buffer.from(errorMessage))

	// Let all users know that the game is starting
	const startMessage: string = JSON.stringify({ type: "StartGame" })
	sendToAll(room, Buffer.from(startMessage), room.host)
}

export async function receivedJustConnectedUser(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {

	// If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance.
	// This is important for when a user disconnects from the internet and reconnects to the internet and to the server.
	if (room.agentUUIDConnection.has(incomingClientUUID)) {
		const agentWebsocket: WebSocket = room.agentUUIDConnection.get(incomingClientUUID)!

		handleWSClosure(room, agentWebsocket);
		console.log(`NOTE: Deleted ${incomingClientUUID} client from room.agentUUIDConnection.`);
	}

	// Save current user's UUID into a dictionary on the server
	room.agentUUIDConnection.set(incomingClientUUID, incomingClient);
	console.log(`${getCurrentTime()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);

	// Send the agent's UUID to agents that previously connected
	sendToAllButSelf(room, message, incomingClient, incomingClientUUID);

	// Send data back to the connecting user
	const sendRoomData = {
		roomID: room.roomID,
		hostUUID: room.host,
		gameState: room.gameState
	};

	// Send the status of the room to the connecting user
	const roomID: string = JSON.stringify({ type: "RoomCharacteristics", payload: sendRoomData });
	sendTo(room, incomingClientUUID, Buffer.from(roomID))
}

// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------

function sendToAll(room: Room, message: Buffer, incomingClientUUID?: string) {
	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client) => {
		if (client) {
			client.send(message);
		}
		// console.log(`${getCurrentTime()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
	});
}

function sendToAllButSelf(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {

	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client) => {
		if (client && client !== incomingClient && client.readyState === WebSocket.OPEN) {
			client.send(message);
			// console.log(`${getCurrentTime()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
		}
	});
}

function sendTo(room: Room, agent: string, message: Buffer) {

	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client) => {
		if (client && client === room.agentUUIDConnection.get(agent) && client.readyState === WebSocket.OPEN) {
			client.send(message);
		}
	});
}

// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------

// (1) Tell other users that a user is disconnecting (2) Delete the user from the room
export async function handleWSClosure(room: Room, incomingClient: WebSocket) {

	// Given the websocket client and the room, return the UUID of the disconnected user.
	const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient);

	// If the uuid exists within the room
	if (disconnectedUserUUID) {
		console.log(`${getCurrentTime()} [Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
		console.log(`${getCurrentTime()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);

		// Create a payload to send to other users
		let disconnectedMessagePayload

		// If the host has disconnected
		if (disconnectedUserUUID === room.host) {

			// Find a user that is not the host
			for (const user of room.agentUUIDConnection.keys()) {
				if (user !== disconnectedUserUUID) {

					disconnectedMessagePayload = { userUUID: disconnectedUserUUID, newHost: user }
					
					// Update the host to some user
					room.host = user

					break
				}
			}
		} else {
			disconnectedMessagePayload = { userUUID: disconnectedUserUUID }
		}

		// Let the other agents know that an user has disconnected from the server
		const disconnectionUserMessage: string = JSON.stringify({ type: "DisconnectedUser", payload: disconnectedMessagePayload });
		sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);

		// If the uuid does not exist within the room
	} else {
		console.log(`${getCurrentTime()} [Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);
	}

	if (room.agentUUIDConnection.size === 0) {
		// Handle deleting the room here. If the room does not exist, no errors are thrown
		roomsContainer.deleteRoomFromRooms(room);
	}
}

// Helper function to delete the user that left the room
export function deleteKeyValuePairAndReturnKey(obj: Map<string, WebSocket | undefined>, targetValue: WebSocket): (string | undefined) {

	for (const [key, value] of obj.entries()) {
		if (value && value === targetValue) {
			// Delete the matching entry
			obj.delete(key);
			// Immediately return the key. 
			return key;
		}
	}
	return undefined; // Return undefined if no matching value is found
}


