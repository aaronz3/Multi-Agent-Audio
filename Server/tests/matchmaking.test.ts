
import { updateRoomReturnWebSocketServer, returnMostSuitableRoomAndUpdateRoomProperty } from "../src/matchmaking"
import { Room, rooms, roomsContainer } from "../src/global-properties";
import WebSocket from "ws";

require('dotenv').config();
const testip = process.env.IP_FOR_TESTS;
const port = process.env.PORT;
const testWSAddress = `${testip}:${port}`

describe('Matchmaking tests', () => {
    beforeEach(() => {
        roomsContainer.setRooms([]);
    })
    
    test('add a room to rooms if no rooms exist', () => {
        updateRoomReturnWebSocketServer()

        expect(roomsContainer.getRoomsLength()).toBe(1)
    });

    test('add a room to rooms if all rooms are full', () => {
        const room = new Room("test-room", new WebSocket.Server({noServer: true}))
        const clients = [ new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`) ]
        
        for (let i = 1; i <= 6; i++) {
            room.agentUUIDConnection.set(`uuid${i}`, clients[i])
        }

        roomsContainer.addRoom(room)

        updateRoomReturnWebSocketServer()

        expect(roomsContainer.getRoomsLength()).toBe(2)
    });

    test('get a current room from rooms if rooms exist', () => {
        const room = new Room("test-room", new WebSocket.Server({noServer: true}))
        const clients = [ new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`), new WebSocket(`ws://${testWSAddress}`) ]
        room.agentUUIDConnection.set("uuid1", clients[0])

        roomsContainer.addRoom(room)

        const wss = returnMostSuitableRoomAndUpdateRoomProperty()

        expect(roomsContainer.getRoomsLength()).toBe(1)
        expect(wss).toBeInstanceOf(WebSocket.Server);
    });

})
