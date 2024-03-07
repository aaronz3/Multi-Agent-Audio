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
        if (wss) {
            wss.handleUpgrade(request, socket, head, (incomingClient) => {
                wss.emit("connection", incomingClient, request);
            });
        }
        else {
            // Send an error to the client
            console.log("DEBUG: Suitable room was not found");
        }
        console.log(`Number of rooms: ${global_properties_1.roomsContainer.getRoomsLength()}`);
    });
}
exports.handlePlay = handlePlay;
// Update rooms array and return a websocket server 
function updateRoomReturnWebSocketServer(uuid) {
    var _a, _b;
    return __awaiter(this, void 0, void 0, function* () {
        let userData;
        // Check the database to see if the user was previously in a game
        try {
            const data = yield accessDB.getUserData(uuid);
            // Returned data object must be defined
            if (data) {
                userData = data;
                // If user's data is not avaliable, which should never be the case at this stage
            }
            else {
                throw new Error("DEBUG: User data does not exist");
            }
            // Get user data must not return an error
        }
        catch (_c) {
            throw new Error("DEBUG: Error in updateRoomReturnWebSocketServer getting user data");
        }
        // IF USER WAS IN A GAME 
        if (((_a = userData["Previous-Room"]) === null || _a === void 0 ? void 0 : _a.S) !== undefined) {
            const previousRoom = (_b = userData["Previous-Room"]) === null || _b === void 0 ? void 0 : _b.S;
            const room = global_properties_1.roomsContainer.getRoom(previousRoom);
            // If the room is not undefined, return its websocket server, else consider the room disband
            return (room != undefined ? room.websocketServer : handleUserNotInGame());
            // IF USER WAS NOT IN A GAME OR GAME DOES NOT EXIST
        }
        else {
            return handleUserNotInGame();
        }
    });
}
exports.updateRoomReturnWebSocketServer = updateRoomReturnWebSocketServer;
function handleUserNotInGame() {
    // If no rooms exists or all rooms are currently full, create a new room
    if (global_properties_1.roomsContainer.getRoomsLength() == 0 || global_properties_1.roomsContainer.roomIsNotAvailable()) {
        const roomUUID = crypto_1.default.randomUUID();
        const wss = new ws_1.default.Server({ noServer: true });
        const room = new global_properties_1.Room(roomUUID, wss);
        // Modify the properties of a room instance when a user connects, sends a message, etc.
        (0, websocket_room_1.modifyRoom)(room);
        // Add the newly created room into the rooms array.
        global_properties_1.roomsContainer.addRoom(room);
        return wss;
        // Else join the room that is about to be filled.
    }
    else {
        const suitableRoom = returnMostSuitableRoomAndUpdateRoomProperty();
        if (suitableRoom) {
            return suitableRoom;
        }
        else {
            return undefined;
        }
    }
}
// Algorithm to put the user in an available room with the most people
function returnMostSuitableRoomAndUpdateRoomProperty() {
    let numberOfPlayersInPreviousRoom = 0;
    let returnRoom;
    for (const room of global_properties_1.rooms) {
        if (room.agentUUIDConnection.size > numberOfPlayersInPreviousRoom && room.agentUUIDConnection.size < global_properties_1.maxNumberOfPlayers) {
            numberOfPlayersInPreviousRoom = room.agentUUIDConnection.size;
            returnRoom = room;
        }
    }
    if (returnRoom) {
        return returnRoom.websocketServer;
    }
    else {
        return undefined;
    }
}
exports.returnMostSuitableRoomAndUpdateRoomProperty = returnMostSuitableRoomAndUpdateRoomProperty;
