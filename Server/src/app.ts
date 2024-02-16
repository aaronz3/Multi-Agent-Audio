import { handlePlay } from "./matchmaking";
import express from "express";

// Use the 'https' module instead of 'http' for production
import http from "http";
import internal from "stream";
// const fs = require('fs')
// import https from 'https';  

const app = express();

require("dotenv").config({ path: '../.env' });
const port = process.env.PORT;

// SECTION: TEST SERVER (ABLE TO RUN ON LOCAL COMPUTER)
// -----------------------
const server = http.createServer(app);

// SECTION: LIVE SERVER
// -----------------------

// Load SSL/TLS certificate and private key
// const serverOptions = {
//   key: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/privkey.pem'),
//   cert: fs.readFileSync('/etc/letsencrypt/live/impactsservers.com/fullchain.pem')
// };

// const server = https.createServer(serverOptions, app);

// SECTION: ADDING WEBSOCKETS TO HTTP(S)
// -----------------------
// Upgrade the HTTP(S) server to a WebSocket server on '/play' route

server.on("upgrade", (request: http.IncomingMessage, socket: internal.Duplex, head: Buffer) => {

	// Check if request.url is defined
    if (request.url && request.headers.host) {
        const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
        if (pathname === "/play") {
            handlePlay(request, socket, head);
        }
    } else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
		console.log("DEBUG: some part of request was undefined")
        socket.destroy();
    }
});

// SECTION: USER ID DATA UPLOADED TO SERVER
// -----------------------

app.post("/user-data", express.json(), (req, res) => {
	console.log("Received data:", req.body);
	res.status(200).send("Data received");
});

server.listen(port, () => {
	console.log(`Server listening on port ${port}`);
});

