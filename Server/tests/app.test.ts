
import { updateRoomReturnWebSocketServer, returnMostSuitableRoomAndUpdateRoomProperty } from "../src/matchmaking"
import { rooms, roomsContainer } from "../src/global-properties";
import WebSocket from "ws";

describe('WebSocket server upgrade', () => {
    beforeEach(() => {
        roomsContainer.setRooms([]);
    })
    
    test('add a room to rooms if no rooms exist', () => {
        updateRoomReturnWebSocketServer()
        rooms[0].numberOfPlayers++;

        expect(roomsContainer.getRoomsLength()).toBe(1)
    });

    test('get a current room from rooms if rooms exist', () => {
        const wss = returnMostSuitableRoomAndUpdateRoomProperty()
        rooms[0].numberOfPlayers++;

        expect(roomsContainer.getRoomsLength()).toBe(1)
        expect(wss).toBeInstanceOf(WebSocket.Server);
    });

    //

})
