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
const user_profile_1 = require("./user-profile");
const express_1 = __importDefault(require("express"));
const multer_1 = __importDefault(require("multer"));
// Use the 'https' module instead of 'http' for production
const http_1 = __importDefault(require("http"));
// const fs = require('fs')
// import https from 'https';  
const app = (0, express_1.default)();
require("dotenv").config();
const port = process.env.PORT;
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
// SECTION: ADDING WEBSOCKETS TO HTTP(S)
// -----------------------
// Upgrade the HTTP(S) server to a WebSocket server on '/play' route
server.on("upgrade", (request, socket, head) => {
    // Check if request.url is defined
    if (request.url && request.headers.host) {
        const pathname = new URL(request.url, `http://${request.headers.host}`).pathname;
        if (pathname === "/play") {
            (0, matchmaking_1.handlePlay)(request, socket, head);
        }
    }
    else {
        // Handle the case where request.url is undefined
        // For example, you might want to close the socket
        console.log("DEBUG: some part of request was undefined");
        socket.destroy();
    }
});
// SECTION: PROFILE PHOTO DATA UPLOAD & DOWNLOAD
// -----------------------
const storage = multer_1.default.memoryStorage();
const upload = (0, multer_1.default)({ storage: storage });
app.post("/upload-profile-photo", upload.single("image"), (req, res) => {
    (0, user_profile_1.handleUploadProfilePhoto)(req);
    res.send("Image uploaded successfully");
});
app.get("/download-profile-photo", (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // Await the async function to get the resolved value
        const photoUrls = yield (0, user_profile_1.handleDownloadProfilePhoto)(req);
        res.send(photoUrls);
    }
    catch (error) {
        // Handle any errors that occur during fetch
        console.error(error);
        res.status(500).send("An error occurred while fetching photos.");
    }
}));
// SECTION: USER ID DATA UPLOADED TO SERVER
// -----------------------
app.post("/user-data", express_1.default.json(), (req, res) => {
    console.log("Received data:", req.body);
    res.status(200).send("Data received");
});
server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});
