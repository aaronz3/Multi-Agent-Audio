import WebSocket from 'ws';

// Room Data
export let rooms: Array<Room> = [];

// TODO:
export const roomsContainer = {
	addRoom: (room: Room) => { rooms.push(room); },
	setRooms: (newRooms: Room[]) => { rooms = newRooms; },
	getRoomsLength: (): number => { return rooms.length; },
	// Helper function to delete the room from the global rooms array if there are no players in the room
	deleteRoomFromRooms: (roomToRemove: Room) => {
		// Find the index of the room to remove
		const index = rooms.findIndex(room => room === roomToRemove);

		// If the room is found in the array, remove it
		if (index !== -1) {
			rooms.splice(index, 1);
		}
		console.log(`Number of rooms: ${rooms.length}`);
	},
	// Helper function to determine if any rooms are available to join
	roomIsNotAvailable: (): boolean => {
		let noRoomsAvailable = true;
	
		for (const room of rooms) {
			if (room.agentUUIDConnection.size > 0 && room.agentUUIDConnection.size < maxNumberOfPlayers) {
				noRoomsAvailable = false;
				// Exit the loop as soon as an available room is found
				break;  
			}
		}
		
		return noRoomsAvailable;
	}

};

// Every room can only have these many players
export const maxNumberOfPlayers = 6;

// Structure of an instance of a room will be as follows 
export class Room {

	roomID: string;
	agentUUIDConnection = new Map<string, WebSocket>();
	websocketServer: WebSocket.Server;
	clientIsAliveMap = new Map<WebSocket, boolean>();

	constructor(roomID: string, websocketServer: WebSocket.Server) {
		this.roomID = roomID;
		this.websocketServer = websocketServer;
	}
}

export interface Message {
	type: string;
	payload: any;
}
