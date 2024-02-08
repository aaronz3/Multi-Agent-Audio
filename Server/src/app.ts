import { handlePlay } from "./matchmaking";
import { handleUploadProfilePhoto, handleDownloadProfilePhoto } from "./user-profile";

import express from "express";
import multer from "multer";

// Use the 'https' module instead of 'http' for production
import http from "http";
import internal from "stream";
// const fs = require('fs')
import https from 'https';  

const app = express();

require("dotenv").config();
const port = process.env.PORT;

// SECTION: TEST SERVER
// -----------------------
const server = https.createServer(app);

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
    if (request.url) {
        const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
        if (pathname === "/play") {
            handlePlay(request, socket, head);
        }
    } else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
		console.log("DEBUG: request.url was undefined")
        socket.destroy();
    }
});

// SECTION: PROFILE PHOTO DATA UPLOAD & DOWNLOAD
// -----------------------
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

app.post("/upload-profile-photo", upload.single("image"), (req, res) => {
	handleUploadProfilePhoto(req);
	res.send("Image uploaded successfully");
});

app.get("/download-profile-photo", async (req, res) => {
	try {
		// Await the async function to get the resolved value
		const photoUrls = await handleDownloadProfilePhoto(req);
		res.send(photoUrls);
	} catch (error) {
		// Handle any errors that occur during fetch
		console.error(error);
		res.status(500).send("An error occurred while fetching photos.");
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

