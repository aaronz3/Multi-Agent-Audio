import WebSocket from "ws";
import { roomsContainer, getCurrentTime, type Room, Message } from "./global-properties";
import { IncomingMessage } from "http";
import { AccessUserDataDynamoDB } from "./access-dynamodb";

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

			case "JustConnectedUser":
				const incomingClientUUID: string = parsedMessage.payload["userUUID"];
				await receivedJustConnectedUser(room, Buffer.from(message), incomingClient, incomingClientUUID);
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
				console.log("Unknown message type:", parsedMessage.type);
		}

	} catch (error) {
		console.error("Error parsing message:", error);
	}
}

// SECTION: RECEVIED MESSAGE TYPES
// -----------------------

export async function receivedJustConnectedUser(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {

	// If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance.
	// The is important for when a user disconnects from the internet and reconnects to the internet and to the server.
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

	// Save the room id onto the user's previous room property on the database
	await accessDB.updateItemInUserData(incomingClientUUID, "Previous-Room", room.roomID)

	// FOR TESTING PURPOSES:
	// Send the room id to the agent that connected
	const roomID: string = JSON.stringify({ type: "RoomCharacteristics", payload: { roomID: room.roomID } });
	sendTo(room, incomingClientUUID, Buffer.from(roomID))
}

// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------

function sendToAllButSelf(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {
	
	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client: WebSocket) => {
		if (client !== incomingClient && client.readyState === WebSocket.OPEN) {
			client.send(message);
			console.log(`${getCurrentTime()} [Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
		}
	});
}

function sendTo(room: Room, agent: string, message: Buffer) {
	
	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client: WebSocket) => {
		if (client === room.agentUUIDConnection.get(agent) && client.readyState === WebSocket.OPEN) {
			client.send(message);
		}
	});
}

// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------

export function handleWSClosure(room: Room, incomingClient: WebSocket) {

	const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient);

	if (disconnectedUserUUID) {
		console.log(`${getCurrentTime()} [Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
		console.log(`${getCurrentTime()} [Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);

		// Let the other agents know that an user has disconnected from the server
		const disconnectionUserMessage: string = JSON.stringify({ type: "DisconnectedUser", payload: { userUUID: disconnectedUserUUID } });
		sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);
	} else {
		console.log(`${getCurrentTime()} [Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);
	}

	if (room.agentUUIDConnection.size == 0) {
		// Handle deleting the room here. If the room does not exist, no errors are thrown
		roomsContainer.deleteRoomFromRooms(room);
	}
}

// Helper function to delete the user that left the room
export function deleteKeyValuePairAndReturnKey(obj: Map<string, WebSocket>, targetValue: WebSocket): (string | undefined) {

	for (const [key, value] of obj.entries()) {
		if (value === targetValue) {
			// Delete the matching entry
			obj.delete(key);
			// Immediately return the key. 
			return key;
		}
	}
	return undefined; // Return undefined if no matching value is found
}


