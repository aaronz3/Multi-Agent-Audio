
import { receivedJustConnectedUser, deleteKeyValuePairAndReturnKey, handleWSClosure } from "../src/websocket-room"
import { Room, rooms, roomsContainer } from "../src/global-properties";
import WebSocket from "ws";

require('dotenv').config();
const testip = process.env.IP_FOR_TESTS;
const port = process.env.PORT;
const testWSAddress = `${testip}:${port}`

describe('Websocket room tests', () => {
    beforeEach(() => {
        roomsContainer.setRooms([]);
    })

    test('delete key value pair and return key', () => {
        const client1 = new WebSocket(`ws://${testWSAddress}`);

        const obj = new Map([
            ['uuid1', client1]
        ])

        const key = deleteKeyValuePairAndReturnKey(obj, client1)
        
        expect(obj.has('uuid1')).toBe(false)
        expect(key).toBe("uuid1")
    })


    test('(1) delete agent UUID from room if incoming client UUID exists (2) delete the room if no clients are in the room', () => {
        const room = new Room("test-room", new WebSocket.Server({ noServer: true }))
        
        roomsContainer.addRoom(room)
        const client1 = new WebSocket(`ws://${testWSAddress}`);
        room.agentUUIDConnection.set("uuid1", client1)
        
        handleWSClosure(room, client1)

        expect(room.agentUUIDConnection.size).toBe(0)
        expect(roomsContainer.getRoomsLength()).toBe(0)
    });

    test('delete previous agent in received just connected user', () => {
        
        const room = new Room("test-room", new WebSocket.Server({ noServer: true }))
        
        roomsContainer.addRoom(room)
        const client1 = new WebSocket(`ws://${testWSAddress}`);
        const client2 = new WebSocket(`ws://${testWSAddress}`);
        room.agentUUIDConnection.set("uuid1", client1)
        
        receivedJustConnectedUser(room, Buffer.from("test-buffer"), client2, "uuid1")

        expect(roomsContainer.getRoomsLength()).toBe(0)
        expect(room.agentUUIDConnection.get("uuid1") === client2).toBeTruthy()

    });

    // INTEGRATION TEST: 
    test('disconnect a user via timer and also reconnection', () => {
        const room = new Room("test-room", new WebSocket.Server({ noServer: true }))
        
        roomsContainer.addRoom(room)
        const client1 = new WebSocket(`ws://${testWSAddress}`);
        room.agentUUIDConnection.set("uuid1", client1)
        
        // Disconnect via reconnection
        receivedJustConnectedUser(room, Buffer.from("test-buffer"), client1, "uuid1")

        // Disconnect via timer
        handleWSClosure(room, client1)
        
        // This should be zero because the room is deleted in handleWSClosure.
        expect(roomsContainer.getRoomsLength()).toBe(0)
        // There should be no agents in this array since you delete the existing uuid1 and then reappend it via receivedJustConnectedUser.
        // Then you delete the uuid1 when executing handleWSClosure.
        expect(room.agentUUIDConnection.size).toBe(0)
    });



})
