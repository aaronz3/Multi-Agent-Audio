import WebSocket from 'ws';

// Room Data
export const rooms: Array<Room> = [];

// Configuration
export const maxNumberOfPlayers = 6;

// Structure of an instance of a room will be as follows 
export class Room {

	roomID: string;
	numberOfPlayers: number;
	agentUUIDConnection: {[key: string]: WebSocket} = {};
	websocketServer: WebSocket.Server;

	constructor(roomID: string, numberOfPlayers: number, websocketServer: WebSocket.Server) {
		this.roomID = roomID;
		this.numberOfPlayers = numberOfPlayers;
		this.websocketServer = websocketServer;
	}
} 
