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
exports.returnMostSuitableRoomAndUpdateRoomProperty = exports.updateRoomReturnWebSocketServer = exports.handlePlay = void 0;
const crypto_1 = __importDefault(require("crypto"));
const ws_1 = __importDefault(require("ws"));
const global_properties_1 = require("./global-properties");
const websocket_room_1 = require("./websocket-room");
const access_dynamodb_1 = require("./access-dynamodb");
require("dotenv").config({ path: '../.env' });
const databaseRegion = process.env.DYNAMODB_BUCKET_REGION;
const accessDB = new access_dynamodb_1.AccessUserDataDynamoDB(databaseRegion);
// Emit a connection on some websocket server when an agent connects
function handlePlay(request, socket, head, url) {
    return __awaiter(this, void 0, void 0, function* () {
        let userUUID;
        // Get user uuid for matchmaking purposes
        if (url.searchParams.get('uuid') === null) {
            // Handle the absence of uuid
            console.log("DEBUG: uuid was undefined");
            return;
        }
        else {
            userUUID = url.searchParams.get('uuid');
        }
        const wss = yield updateRoomReturnWebSocketServer(userUUID);
        wss.handleUpgrade(request, socket, head, (incomingClient) => {
            wss.emit("connection", incomingClient, request);
        });
        console.log(`Number of rooms: ${global_properties_1.roomsContainer.getRoomsLength()}`);
    });
}
exports.handlePlay = handlePlay;
// Update rooms array and return a websocket server 
function updateRoomReturnWebSocketServer(uuid) {
    var _a;
    return __awaiter(this, void 0, void 0, function* () {
        const userData = yield accessDB.getDataInTable("User-Data", "User-ID", uuid);
        const previousRoomUUID = (_a = userData["Previous-Room"]) === null || _a === void 0 ? void 0 : _a.S; // The previous room string exists
        // IF USER WAS NOT IN A GAME OR GAME DOES NOT EXIST
        if (previousRoomUUID === undefined) {
            return handleUserNotInGame(uuid);
        }
        // IF USER WAS IN A GAME 
        const room = global_properties_1.roomsContainer.getRoom(previousRoomUUID); // The server still has a record of the room
        // If the room is still available, return its websocket server, else consider the room disband
        if (room) {
            // Add the user to the room
            room.agentUUIDConnection.set(uuid, undefined);
            return room.websocketServer;
        }
        else {
            return handleUserNotInGame(uuid);
        }
    });
}
exports.updateRoomReturnWebSocketServer = updateRoomReturnWebSocketServer;
function handleUserNotInGame(uuid) {
    // If a room exists or some room still has space, return the most suitable room
    const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty();
    if (suitableRoom) {
        // Add the user to the room 
        suitableRoom.agentUUIDConnection.set(uuid, undefined);
        // Return the room
        return suitableRoom.websocketServer;
        // If for some reason no suitable room was found 
    }
    else {
        return returnNewRoom(uuid);
    }
}
function returnNewRoom(uuid) {
    // Create a new room
    const roomUUID = crypto_1.default.randomUUID();
    const wss = new ws_1.default.Server({ noServer: true });
    const room = new global_properties_1.Room(roomUUID, wss, uuid);
    // Modify the properties of a room instance when a user connects, sends a message, etc.
    (0, websocket_room_1.modifyRoom)(room);
    // Add the newly created room into the rooms array.
    global_properties_1.roomsContainer.addRoom(room);
    return wss;
}
// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
    let numberOfPlayersInPreviousRoom = 0;
    let returnRoom;
    for (const room of global_properties_1.rooms) {
        if (numberOfPlayersInPreviousRoom < room.agentUUIDConnection.size
            && room.agentUUIDConnection.size < global_properties_1.maxNumberOfPlayers
            && room.gameState === "InLobby") {
            numberOfPlayersInPreviousRoom = room.agentUUIDConnection.size;
            returnRoom = room;
        }
    }
    if (returnRoom) {
        return returnRoom;
    }
    else {
        return undefined;
    }
}
exports.returnMostSuitableRoomAndUpdateRoomProperty = returnMostSuitableRoomAndUpdateRoomProperty;
