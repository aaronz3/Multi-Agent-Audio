const express = require('express');
// const http = require('http');  // Use the 'https' module instead of 'http' for production
const https = require('https');  // Use the 'https' module instead of 'http' for production
const fs = require('fs')
const {handlePlay} = require('./matchmaking')

const app = express();
const port = 3000;

// Test server
// const server = http.createServer(app);

// Live server: Load SSL/TLS certificate and private key
const serverOptions = {
  key: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/privkey.pem'),
  cert: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/fullchain.pem')
};

// Create an HTTPS server
const server = https.createServer(serverOptions, app);

// SECTION: ADDING WEBSOCKETS TO HTTP(S)
// -----------------------

// Upgrade the HTTP(S) server to a WebSocket server on '/play' route
server.on('upgrade', (request, socket, head) => {
  console.log("entered upgrade")
  const pathname = new URL(request.url, `https://${request.headers.host}`).pathname;
  if (pathname === '/play') {
    console.log("entered play")
    handlePlay(request, socket, head)
  } 
});

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

