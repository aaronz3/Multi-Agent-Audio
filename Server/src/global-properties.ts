import WebSocket from 'ws';

// Room Data
export let rooms: Array<Room> = [];

// TODO:
export const roomsContainer = {
	addRoom: (room: Room) => { rooms.push(room); },
	setRooms: (newRooms: Room[]) => { rooms = newRooms; },
	getRoomsLength: (): number => { return rooms.length; },
	// Helper function to get a room given the room id
	getRoom: (roomUUID: string): Room | undefined => { 
		for (const room of rooms) {
			if (room.roomID == roomUUID) {
				return room
			}
		}
		return undefined
	},
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
			if (0 < room.agentUUIDConnection.size && room.agentUUIDConnection.size < maxNumberOfPlayers) {
				noRoomsAvailable = false;
				// Exit the loop as soon as an available room is found
				break;  
			}
		}
		
		return noRoomsAvailable;
	}

};

// Every room can only have these many players
export const maxNumberOfPlayers = 2;

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

// For debugging purposes print the current time of events
export const getCurrentTime = () => {
    const now = new Date(); // Create a new date object with the current date and time

    // Extract the day, hour, minute, and second
    const month = now.getMonth() + 1; // Month
    const day = now.getDate(); // Day of the month
    const year = now.getFullYear(); // Year
    const hour = now.getHours(); // Hour (0-23)
    const minute = now.getMinutes(); // Minute (0-59)
    const second = now.getSeconds(); // Second (0-59)

    // Return the time components
    return `[DAY: ${month}-${day}-${year}. TIME: ${hour}:${minute}:${second}]`
};