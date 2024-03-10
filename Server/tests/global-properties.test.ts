
import { Room, roomsContainer } from "../src/global-properties";
import WebSocket from "ws";

describe('Matchmaking tests', () => {
    beforeEach(() => {
        roomsContainer.setRooms([]);
    })
    
    test('delete room in rooms', () => {
        
        const room1 = new Room("1", new WebSocket.Server({noServer: true}), "host")
        const room2 = new Room("2", new WebSocket.Server({noServer: true}), "host")
        roomsContainer.addRoom(room1)
        roomsContainer.addRoom(room2)
        roomsContainer.deleteRoomFromRooms(room1)

        expect(roomsContainer.getRoomsLength()).toBe(1)
        expect(roomsContainer.getRoom(room2.roomID)).toBeDefined()
    });


})
