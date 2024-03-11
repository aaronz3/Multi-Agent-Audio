import { handlePlay } from "./matchmaking";
import { handleSetUserData, handleGetUserData, handleSetUserStatus, handleScanUsersStatus } from "./authentication";
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

server.on("upgrade", async (request: http.IncomingMessage, socket: internal.Duplex, head: Buffer) => {

    // Check if request.url and request.headers.host is defined
    if (request.url && request.headers.host) {
        const url: URL = new URL(request.url, `http://${request.headers.host}`);
        const pathname: string = url.pathname;

        // Handle the play path 
        if (pathname === "/play") {
            playConnectionQueue.push({ request, socket, head, url });
            await processNextPlayConnection();
        }
        
    } else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
        console.log("DEBUG: some part of request was undefined")
        socket.destroy();
    }
});

// Define a type for the queue items
type PlayConnectionQueueItem = {
    request: http.IncomingMessage;
    socket: internal.Duplex;
    head: Buffer;
    url: URL;
};

// Queue to hold the connections
const playConnectionQueue: PlayConnectionQueueItem[] = [];

// Flag to indicate if a connection is currently being processed
let isPlayConnectionProcessing = false;

// Recursive function to process the next item in the queue
async function processNextPlayConnection() {
    
    // If the queue is currently processing or finished processing queue, exit the function
    if (isPlayConnectionProcessing || playConnectionQueue.length === 0) {
        return;
    }

    isPlayConnectionProcessing = true;
    const connectionItem = playConnectionQueue.shift();

    if (connectionItem) {
        const { request, socket, head, url } = connectionItem;
        
        try {
            await handlePlay(request, socket, head, url);
        } catch (error) {
            console.log("DEBUG: Error in upgrading to /play", error);
            // Optionally handle error, for example, by closing the socket
            socket.destroy();
        // Trigger processing the next item
        } finally {
            isPlayConnectionProcessing = false;
            processNextPlayConnection();
        }
    } else {
        // Ensure processing flag is reset if no item was found
        isPlayConnectionProcessing = false;
    }
}

// SECTION: USER ID DATA UPLOADED TO SERVER
// -----------------------

// Get necessary user details when login and respond to client
app.get("/login", express.json(), async (req: Request, res: Response) => {
    try {
        // User data may return undefined to specifically signal that the user data does not exist
        const data = await handleGetUserData(req.query)
        if (data) {
            res.json(data);
        } else {
            // No data found for userID, send a 404 response
            res.status(404).json({ message: "User data not found" });
        }
    } catch (e) {
        res.status(500).send(e)
    }
});

// Update the player data and respond to client
app.post("/login", express.json(), async (req: Request, res: Response) => {
    try {
        await handleSetUserData(req.body)
        res.status(200).send("Data Received")
    } catch (e) {
        res.status(500).send(e)
    }
});

// Get all users status and respond to client
app.get("/status", express.json(), async (req: Request, res: Response) => {
    try {
        // User data may return undefined to specifically signal that the user data does not exist
        const data = await handleScanUsersStatus()
        if (data) {
            res.json(data);
        } else {
            // No data found for userID, send a 404 response
            res.status(404).json({ message: "User data not found" });
        }
    } catch (e) {
        res.status(500).send(e)
    }
    
});

// Update the player status and respond to client
app.post("/status", express.json(), async (req: Request, res: Response) => {
    try {
        await handleSetUserStatus(req.body)
        res.status(200).send("Data Received")
    } catch (e) {
        res.status(500).send(e)
    }
});

server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});

