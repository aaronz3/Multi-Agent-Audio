//
//  SignalingTest.swift
//  AudioTests
//
//  Created by Aaron Zheng on 1/21/24.
//

import XCTest
@testable import Audio

// Note to run these tests properly, the server needs to be running

final class SignalingTest: XCTestCase {

    var signalingClient: SignalingClient!
    var websocket: MockNetworkSocket!
    
    override func setUp() {
        let url = URL(string: "ThisURLDoesNotMatter")!
              //  URL(string: "wss://impactsservers.com:3000")!
              //  URL(string: "ws://172.20.10.7:3000")!
        
        websocket = MockNetworkSocket()
        signalingClient = SignalingClient(url: url, currentUserUUID: "THISUSER", websocket: websocket)
    }
    
    override func tearDown() {
        websocket = nil
        signalingClient = nil
    }
    
    func testSignalingClientInitializer() {
        XCTAssertNotNil(signalingClient.currentUserUUID)
    }
    
    // (1) The signaling class should send a user's UUID to the server when he connects
    // (2) When the user disconnects, the readMessage() method should exit and stop running
    func testSendUUIDAfterConnectingAndSuccessfullyDisconnectWebsockets() async throws {
        let expectation = XCTestExpectation(description: "(1) Connected/sent UUID & (2) Disconnected websockets")
        expectation.expectedFulfillmentCount = 3
        
        var previousData: [String] = []
        
        websocket.result = { data in
            switch data {
            case "resume":
                previousData.append("resume")
                expectation.fulfill()
            
            case "send":
                expectation.fulfill()
                previousData.append("send")
                
            case "cancelled":
                expectation.fulfill()
                previousData.append("cancelled")
                                 
            default: print("DEBUG: Data fell")
            }
        }
        
        try await signalingClient.connect(websocket: websocket)

        signalingClient.disconnect()

        await fulfillment(of: [expectation])
        
        XCTAssertTrue(previousData == ["resume", "send", "cancelled"])
    }
    
//    func testErrorWhenReceivingIfWebsocketDisconnects() throws {
//       
//        
//    }
}
