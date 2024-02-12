import WebSocket from "ws";
import { roomsContainer, type Room, Message } from "./global-properties";

// SECTION: MODIFY ROOM PROPERTIES
// -----------------------

// Update agentUUIDConnection of room
export function modifyRoom(room: Room) {  
	// Create a Map to track the 'isAlive' property for each client

	const wss: WebSocket.Server = room.websocketServer;
	wss.on("connection", (incomingClient: WebSocket, req) => {
		
		room.numberOfPlayers++;

		console.log(`[Room ${room.roomID}] Client connected from IP: ${req.socket.remoteAddress}. Total connected clients: ${wss.clients.size}.`);
		
		// Initialize the 'isAlive' property for the new client
		room.clientIsAliveMap.set(incomingClient, true);

		// Handle message
		incomingClient.on("message", (message) => {
			// Ensure message is treated as a string regardless of its original type
			let messageAsString: string;
			if (Buffer.isBuffer(message)) {
				messageAsString = message.toString(); // Default fallback, might choose to handle differently
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
	});

	function heartbeat() {
		wss.clients.forEach((ws) => {
			if (room.clientIsAliveMap.get(ws) === false) {
				return ws.terminate();
			}
	
			room.clientIsAliveMap.set(ws, false);
			ws.ping();
		});
	}

	setInterval(heartbeat, 10000);
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
			
			// Check if room.agentUUIDConnection already has a reference to the client. If so, terminate the previous instance. If note, add the client to room.agentUUIDConnection.
			receivedJustConnectedUser(room, Buffer.from(message), incomingClient, incomingClientUUID);

			break;
        
		case "SessionDescription":
			const forwardingAddressForSDP: string = parsedMessage.payload["toUUID"];
			console.log(`[Room ${room.roomID}] Sent SDP to ${forwardingAddressForSDP}`);
			sendTo(room, forwardingAddressForSDP, message);
			break;

		case "IceCandidate":
			const forwardingAddressForICECandidate: string = parsedMessage.payload["toUUID"];

			console.log(`[Room ${room.roomID}] Sent candidate to ${forwardingAddressForICECandidate}`);
			sendTo(room, forwardingAddressForICECandidate, message);

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

function receivedJustConnectedUser(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {
	
	// If the incoming client already exists in room.agentUUIDConnection, terminate the previous instance
	if (incomingClientUUID in room.agentUUIDConnection) {
		
		room.agentUUIDConnection[incomingClientUUID].terminate();
		delete room.agentUUIDConnection[incomingClientUUID];
		
		handleWSClosure(room, room.agentUUIDConnection[incomingClientUUID]);
		console.log(`NOTE: Deleted ${incomingClientUUID} client from room.agentUUIDConnection.`);
		console.log(`NOTE: Total connected clients is ${room.websocketServer.clients.size}.`);
		room.numberOfPlayers--;
	} 
	
	// Save current user's UUID into a dictionary on the server
	room.agentUUIDConnection[incomingClientUUID] = incomingClient;
	console.log(`[Room ${room.roomID}] All collected keys are: ${Object.keys(room.agentUUIDConnection)}`);

	// Send the agent's UUID to agents that previously connected
	sendToAllButSelf(room, message, incomingClient, incomingClientUUID);

}

// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------

function sendToAllButSelf(room: Room, message: Buffer, incomingClient: WebSocket, incomingClientUUID: string) {
	Object.values(room.agentUUIDConnection).forEach((client) => {
		if (client !== incomingClient && client.readyState === WebSocket.OPEN) {
			client.send(message);
			console.log(`[Room ${room.roomID}] User ${incomingClientUUID} sent UUID to 1 other users`);
		}
	});
}

function sendTo(room: Room, agent: string, message: string) {
	const wss = room.websocketServer;

	wss.clients.forEach((client) => {
		if (client === room.agentUUIDConnection[agent] && client.readyState === WebSocket.OPEN) {
			client.send(message);
		}
	});
}

// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------

function handleWSClosure(room: Room, incomingClient: WebSocket) {
	
	const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient);
	room.numberOfPlayers--;

	if (disconnectedUserUUID === undefined) {
		console.log(`[Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`);
    
	} else {
		console.log(`[Room ${room.roomID}] Client ${disconnectedUserUUID} closed the connection`);

		const disconnectionUserMessage: string = JSON.stringify({ type: "DisconnectedUser", payload: { userUUID: disconnectedUserUUID }});
		
		sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient, disconnectedUserUUID);	
		
		console.log(`[Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
		console.log(`[Room ${room.roomID}] All collected keys are: ${Object.keys(room.agentUUIDConnection)}`);
	}

	if (room.numberOfPlayers == 0) {
		// Handle deleting the room here
		roomsContainer.deleteRoomFromRooms(room);
	}
}

// Helper function to delete the user that left the room
function deleteKeyValuePairAndReturnKey(obj: {[key: string]: WebSocket}, targetValue: WebSocket): (string | undefined) {
	for (const key in obj) {
		if (obj[key] === targetValue) {
			delete obj[key];
			return key;  
		}
	}
}

