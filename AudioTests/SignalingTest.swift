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

    var signalingClient: SignalingClient! = nil

    override func setUp() {
        let url = URL(string: "wss://impactsservers.com:3000")!
              //  URL(string: "wss://impactsservers.com:3000")!
              //  URL(string: "ws://172.20.10.7:3000")!
        signalingClient = SignalingClient(url: url)
    }
    
    override func tearDown() {
        signalingClient = nil
    }
    
    func testSignalingClientInitializer() {
        XCTAssertTrue(signalingClient.currentUserUUID == CurrentUserModel.loadUsername())
        print("TEST OUTPUT: Current user username: \(signalingClient.currentUserUUID!)")
    }
    
    // (1) The signaling class should send a user's UUID to the server when he connects
    // (2) When the user disconnects, the readMessage() method should exit and stop running
    func testSendUUIDAfterConnectingAndSuccessfullyDisconnectWebsockets() async throws {
        let expectation = XCTestExpectation(description: "(1) Connected/sent UUID & (2) Disconnected websockets")
        expectation.expectedFulfillmentCount = 3
        
        var previousData: [String] = []
        
        signalingClient.processDataCompletion = { data in
            switch data {
            case "current connected agent's UUID":
                previousData.append("current connected agent's UUID")
                expectation.fulfill()
            
            case "Disconnected":
                if previousData.contains(where: { $0 == "Disconnected" }) {
                    XCTFail("TEST FAILED: Disconnected returned twice")
                } else {
                    expectation.fulfill()
                    previousData.append("Disconnected")

                }
                
            case "FailedInReceiving":
                if previousData.contains(where: { $0 == "FailedInReceiving" }) {
                    XCTFail("TEST FAILED: FailedInReceiving returned twice")
                } else {
                    expectation.fulfill()
                    previousData.append("FailedInReceiving")
                }
                            
            default: print("DEBUG: Data fell")
            }
        }
        
        try await signalingClient.connect()

        signalingClient.disconnect()

        await fulfillment(of: [expectation])
        
    }
    
//    func testErrorWhenReceivingIfWebsocketDisconnects() throws {
//       
//        
//    }
}
