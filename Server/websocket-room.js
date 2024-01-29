const WebSocket = require('ws');
const {rooms} = require('./global-properties');

// SECTION: MODIFY ROOM PROPERTIES
// -----------------------

// Update agentUUIDConnection of room
function modifyRoom(room) {  
  const wss = room.websocketServer
  wss.on('connection', (incomingClient) => {
    room.numberOfPlayers++;

    console.log(`[Room ${room.roomID}] Client connected from IP: ${incomingClient._socket.remoteAddress}. Total connected clients: ${wss.clients.size}.`);

    // Handle message
    incomingClient.on('message', (message) => {
      handleWSMessage(room, message, incomingClient)
    });
  
    // Handle websocket closure
    incomingClient.on('close', () => {
      handleWSClosure(room, incomingClient)
    });
      
  });
}

// SECTION: HANDLE WEBSOCKET MESSAGE EVENT
// -----------------------

function handleWSMessage(room, message, incomingClient) {
  try {
    const parsedMessage = JSON.parse(message);
    
    switch (parsedMessage.type) {
      
      case 'JustConnectedUser':

        // This is the current user's UUID
        const incomingClientUUID = parsedMessage.payload["userUUID"];
        
        // Save current user's UUID into a dictionary on the server
        room.agentUUIDConnection[incomingClientUUID] = incomingClient;
        console.log(`[Room ${room.roomID}] All collected keys are: ${Object.keys(room.agentUUIDConnection)}`);

        // Send the agent's UUID to agents that previously connected
        sendToAllButSelf(room, message, incomingClient);

        console.log(`[Room ${room.roomID}] User ${incomingClientUUID} sent UUID to ${room.websocketServer.clients.size - 1} other users`)
        break;
        
      case 'SessionDescription':
        const forwardingAddressForSDP = parsedMessage.payload["toUUID"];
        console.log(`[Room ${room.roomID}] Sent SDP to ${forwardingAddressForSDP}`)
        sendTo(room, forwardingAddressForSDP, message);
        break;

      case 'IceCandidate':
        const forwardingAddressForICECandidate = parsedMessage.payload["toUUID"];

        console.log(`[Room ${room.roomID}] Sent candidate to ${forwardingAddressForICECandidate}`)
        sendTo(room, forwardingAddressForICECandidate, message);

        break;

      default:
        console.log('Unknown message type:', parsedMessage.type);
    }
    
  } catch (error) {
    console.error('Error parsing message:', error);
  }
}

// SECTION: HELPERS TO RELAY MESSAGES 
// -----------------------

function sendToAllButSelf(room, message, incomingClient) {
  const wss = room.websocketServer

  wss.clients.forEach((client) => {
    if (client !== incomingClient && client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

function sendTo(room, agent, message) {
  const wss = room.websocketServer

  wss.clients.forEach((client) => {
    if (client === room.agentUUIDConnection[agent] && client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// SECTION: HANDLE WEBSOCKET CLOSURE EVENT
// -----------------------

function handleWSClosure(room, incomingClient) {
  console.log(`[Room ${room.roomID}] Some client closed the connection`)
    const disconnectedUserUUID = deleteKeyValuePairAndReturnKey(room.agentUUIDConnection, incomingClient)
    room.numberOfPlayers--;

    if (disconnectedUserUUID === null || disconnectedUserUUID === undefined) {
      console.log(`[Room ${room.roomID}] DEBUG: The server tried to delete a client that was not in agentUUIDConnection array`)
    
    } else {
      const disconnectionUserMessage = JSON.stringify({ type: 'DisconnectedUser', payload: { userUUID: disconnectedUserUUID }})
      sendToAllButSelf(room, Buffer.from(disconnectionUserMessage), incomingClient);

      console.log(`[Room ${room.roomID}] DisconnectedUserUUID: ${disconnectedUserUUID}`);
      console.log(`[Room ${room.roomID}] All collected keys are: ${Object.keys(room.agentUUIDConnection)}`);
    }

    if (room.numberOfPlayers == 0) {
      // Handle deleting the room here
      deleteRoomFromRooms(room)
    }
}

// Helper function to delete the user that left the room
function deleteKeyValuePairAndReturnKey(obj, targetValue) {
  for (const key in obj) {
    if (obj[key] === targetValue) {
      delete obj[key];
      return key  
    }
  }
}

// Helper function to delete the room from the global rooms array if there are no players in the room
function deleteRoomFromRooms(roomToRemove) {
  // Find the index of the room to remove
  const index = rooms.findIndex(room => room === roomToRemove);

  // If the room is found in the array, remove it
  if (index !== -1) {
    rooms.splice(index, 1);
  }
  console.log(`Number of rooms: ${rooms.length}`)
}

module.exports = modifyRoom;