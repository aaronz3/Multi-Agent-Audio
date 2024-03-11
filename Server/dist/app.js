"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const matchmaking_1 = require("./matchmaking");
const authentication_1 = require("./authentication");
const express_1 = __importDefault(require("express"));
// Use the 'https' module instead of 'http' for production
const http_1 = __importDefault(require("http"));
// const fs = require('fs')
// import https from 'https';  
const app = (0, express_1.default)();
// SECTION: TEST SERVER (ABLE TO RUN ON LOCAL COMPUTER)
// -----------------------
const server = http_1.default.createServer(app);
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
server.on("upgrade", (request, socket, head) => __awaiter(void 0, void 0, void 0, function* () {
    // Check if request.url and request.headers.host is defined
    if (request.url && request.headers.host) {
        const url = new URL(request.url, `http://${request.headers.host}`);
        const pathname = url.pathname;
        // Handle the play path 
        if (pathname === "/play") {
            playConnectionQueue.push({ request, socket, head, url });
            yield processNextPlayConnection();
        }
    }
    else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
        console.log("DEBUG: some part of request was undefined");
        socket.destroy();
    }
}));
// Queue to hold the connections
const playConnectionQueue = [];
// Flag to indicate if a connection is currently being processed
let isPlayConnectionProcessing = false;
// Recursive function to process the next item in the queue
function processNextPlayConnection() {
    return __awaiter(this, void 0, void 0, function* () {
        // If the queue is currently processing or finished processing queue, exit the function
        if (isPlayConnectionProcessing || playConnectionQueue.length === 0) {
            return;
        }
        isPlayConnectionProcessing = true;
        const connectionItem = playConnectionQueue.shift();
        if (connectionItem) {
            const { request, socket, head, url } = connectionItem;
            try {
                yield (0, matchmaking_1.handlePlay)(request, socket, head, url);
            }
            catch (error) {
                console.log("DEBUG: Error in upgrading to /play", error);
                // Optionally handle error, for example, by closing the socket
                socket.destroy();
                // Trigger processing the next item
            }
            finally {
                isPlayConnectionProcessing = false;
                processNextPlayConnection();
            }
        }
        else {
            // Ensure processing flag is reset if no item was found
            isPlayConnectionProcessing = false;
        }
    });
}
// SECTION: USER ID DATA UPLOADED TO SERVER
// -----------------------
// Get necessary user details when login and respond to client
app.get("/login", express_1.default.json(), (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // User data may return undefined to specifically signal that the user data does not exist
        const data = yield (0, authentication_1.handleGetUserData)(req.query);
        if (data) {
            res.json(data);
        }
        else {
            // No data found for userID, send a 404 response
            res.status(404).json({ message: "User data not found" });
        }
    }
    catch (e) {
        res.status(500).send(e);
    }
}));
// Update the player data and respond to client
app.post("/login", express_1.default.json(), (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        yield (0, authentication_1.handleSetUserData)(req.body);
        res.status(200).send("Data Received");
    }
    catch (e) {
        res.status(500).send(e);
    }
}));
// Get all users status and respond to client
app.get("/status", express_1.default.json(), (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // User data may return undefined to specifically signal that the user data does not exist
        const data = yield (0, authentication_1.handleScanUsersStatus)();
        if (data) {
            res.json(data);
        }
        else {
            // No data found for userID, send a 404 response
            res.status(404).json({ message: "User data not found" });
        }
    }
    catch (e) {
        res.status(500).send(e);
    }
}));
// Update the player status and respond to client
app.post("/status", express_1.default.json(), (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        yield (0, authentication_1.handleSetUserStatus)(req.body);
        res.status(200).send("Data Received");
    }
    catch (e) {
        res.status(500).send(e);
    }
}));
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
