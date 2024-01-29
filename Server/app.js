const express = require('express');
const crypto = require('crypto');
const WebSocket = require('ws');
const http = require('http');  // Use the 'https' module instead of 'http' for production

const modifyRoom = require('./websocket-room');
const {rooms, maxNumberOfPlayers} = require('./global-properties');

const app = express();
const port = 3000;

const server = http.createServer(app);

// For a live server
// // Load your SSL/TLS certificate and private key
// const serverOptions = {
//   key: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/privkey.pem'),
//   cert: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/fullchain.pem'),
// };

// // Create an HTTPS server
// const server = https.createServer(serverOptions, app);

// SECTION: UPGRADING HTTP TO WEBSOCKETS
// -----------------------

// Upgrade the HTTP server to a WebSocket server on '/ws' route
server.on('upgrade', (request, socket, head) => {
  const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;

  if (pathname === '/play') {
    
    let wss 

    // If room is empty or all rooms are currently full, create a new room
    if (rooms.length == 0 || roomIsNotAvailable()) {
      const roomUUID = crypto.randomUUID()
      wss = new WebSocket.Server({ noServer: true });

      const newRoom = {
        roomID: roomUUID,
        numberOfPlayers: 0,
        agentUUIDConnection: [],
        websocketServer: wss
      };

      // Modify the properties of a room instance when a user connects, sends a message, etc.
      modifyRoom(newRoom)
      
      // Add the newly created room into the rooms array.
      rooms.push(newRoom)

    // Else join the room that is about to be filled.
    } else {
      wss = returnMostSuitableRoomAndUpdateRoomProperty()
    }

    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
    
    console.log(`Number of rooms: ${rooms.length}`)

  } else {
    socket.destroy();
  }
});

// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
  let numberOfPlayersInPreviousRoom = 0;
  let returnRoom;
  
  for (const room of rooms) {
    if (room.numberOfPlayers > numberOfPlayersInPreviousRoom && room.numberOfPlayers < maxNumberOfPlayers) {
      numberOfPlayersInPreviousRoom = room.numberOfPlayers;
      returnRoom = room;
    }
  }

  return returnRoom.websocketServer;
}

// Helper function to determine if any rooms are available to join
function roomIsNotAvailable() {
  let noRoomsAvailable = true;
  for (const room of rooms) {
    if (room.numberOfPlayers > 0 && room.numberOfPlayers < maxNumberOfPlayers) {
      noRoomsAvailable = false;
      // Exit the loop as soon as an available room is found
      break;  
    }
  }
  return noRoomsAvailable;
};

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

