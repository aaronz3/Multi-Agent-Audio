import { handlePlay } from "./matchmaking";
import { handleSetUserData, handleGetUserData } from "./authentication";
import { Request, Response } from 'express';
import express from "express";

// Use the 'https' module instead of 'http' for production
import http from "http";
import internal from "stream";
// const fs = require('fs')
// import https from 'https';  

const app = express();

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

require("dotenv").config({ path: '../.env' });
const port = process.env.PORT;

// SECTION: ADDING WEBSOCKETS TO HTTP(S)
// -----------------------
// Upgrade the HTTP(S) server to a WebSocket server on '/play' route

server.on("upgrade", (request: http.IncomingMessage, socket: internal.Duplex, head: Buffer) => {

	// Check if request.url and request.headers.host is defined
    if (request.url && request.headers.host) {
        const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
        
        // Handle the play path 
        if (pathname === "/play") {
            handlePlay(request, socket, head);
        }

        // Handle other paths here

    } else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
		console.log("DEBUG: some part of request was undefined")
        socket.destroy();
    }
});

// SECTION: USER ID DATA UPLOADED TO SERVER
// -----------------------

// Get necessary user details when login
app.get("/login", express.json(), async (req: Request, res: Response) => {
    try {
        const data = await handleGetUserData(req.query)
        if (data) {
            res.json(data);
        } else {
            // No data found for userID, send a 404 Not Found response
            res.status(404).json({ message: "User data not found" });
        }
    } catch(e) {
        res.status(500).send(e)
    }
});

// Update the database
app.post("/login", express.json(), async (req: Request, res: Response) => {
    try {
        await handleSetUserData(req.body)
        res.status(200).send("Data Received")
    } catch(e) {
        res.status(500).send(e)
    }
});

server.listen(port, () => {
	console.log(`Server listening on port ${port}`);
});

