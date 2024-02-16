import WebSocket from "ws";
import { roomsContainer, type Room, Message } from "./global-properties";
import { IncomingMessage } from "http";

// SECTION: MODIFY ROOM PROPERTIES
// -----------------------

// Update agentUUIDConnection of room
export function modifyRoom(room: Room) {
	// Create a Map to track the 'isAlive' property for each client

	const wss: WebSocket.Server = room.websocketServer;
	wss.on("connection", (incomingClient: WebSocket, req: IncomingMessage) => {

		console.log(`[Room ${room.roomID}] Client connected from IP: ${req.socket.remoteAddress}. Total connected clients: ${wss.clients.size}.`);

		// Initialize the 'isAlive' property for the new client
		room.clientIsAliveMap.set(incomingClient, true);

		// Handle message
		incomingClient.on("message", (message) => {
			// Ensure message is treated as a string regardless of its original type
			let messageAsString: string;
			if (Buffer.isBuffer(message)) {
				messageAsString = message.toString();
			} else {
				console.log(`DEBUG: Unhandled message type ${message}`);
				return;
			}

			handleWSMessage(room, messageAsString, incomingClient);
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

	const heartbeatInterval = setInterval(heartbeat, 10000);
	heartbeatInterval.unref();
}


// SECTION: HANDLE WEBSOCKET MESSAGE EVENT
// -----------------------

function handleWSMessage(room: Room, message: string, incomingClient: WebSocket) {
	try {
		const parsedMessage: Message = JSON.parse(message);

		switch (parsedMessage.type) {

			case "JustConnectedUser":

				// This is the current user's UUID
				const incomingClientUUID: string = parsedMessage.payload["userUUID"];

				// Check if room.agentUUIDConnection already has a reference to the client. If so, terminate the previous instance. 
				// If not, add the client to room.agentUUIDConnection.
				receivedJustConnectedUser(room, Buffer.from(message), incomingClient, incomingClientUUID);
				break;

			case "SessionDescription":
				const forwardingAddressForSDP: string = parsedMessage.payload["toUUID"];
				console.log(`[Room ${room.roomID}] Sent SDP to ${forwardingAddressForSDP}`);
				sendTo(room, forwardingAddressForSDP, Buffer.from(message));
				break;

			case "IceCandidate":
				const forwardingAddressForICECandidate: string = parsedMessage.payload["toUUID"];

				console.log(`[Room ${room.roomID}] Sent candidate to ${forwardingAddressForICECandidate}`);
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

export function receivedJustConnectedUser(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {

	// If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance
	if (room.agentUUIDConnection.has(incomingClientUUID)) {
		const agentWebsocket: WebSocket = room.agentUUIDConnection.get(incomingClientUUID)!
		
		handleWSClosure(room, agentWebsocket);
		console.log(`NOTE: Deleted ${incomingClientUUID} client from room.agentUUIDConnection.`);
	}

	// Save current user's UUID into a dictionary on the server
	room.agentUUIDConnection.set(incomingClientUUID, incomingClient);
	console.log(`[Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);

	// Send the agent's UUID to agents that previously connected
	sendToAllButSelf(room, message, incomingClient, incomingClientUUID);
}

// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------

function sendToAllButSelf(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {
	
	// The agent must belong in room.agentUUIDConnection
	room.agentUUIDConnection.forEach((client: WebSocket) => {
		if (client !== incomingClient && client.readyState === WebSocket.OPEN) {
			client.send(message);
			console.log(`[Room ${room.roomID}] User ${incomingClientUUID} sent message to 1 other users`);
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

	if (disconnectedUserUUID === undefined) {
		console.log(`[Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);

	} else {
		console.log(`[Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
		console.log(`[Room ${room.roomID}] All collected keys are: ${Array.from(room.agentUUIDConnection.keys())}`);

		// Let the other agents know that an user has disconnected from the server
		const disconnectionUserMessage: string = JSON.stringify({ type: "DisconnectedUser", payload: { userUUID: disconnectedUserUUID } });
		sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);
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


