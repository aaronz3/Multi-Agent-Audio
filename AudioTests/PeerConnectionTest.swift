//
//  AudioTests.swift
//  AudioTests
//
//  Created by Aaron Zheng on 1/20/24.
//

import XCTest
@testable import Audio

final class AudioTests: XCTestCase {
    
    var webRTCModel: WebRTCModel! = nil
    
    override func setUp() {
        webRTCModel = WebRTCModel()
    }
    
    override func tearDown() {
        webRTCModel = nil
    }

    func testNoPeerConnectionsIfJustInitializedWebRTCModel() {
        XCTAssertTrue(webRTCModel.peerConnections.count == 1)
        XCTAssertNil(webRTCModel.peerConnections[0].receivingAgentsUUID)
    }
    
    func testDecodeUserMessage() throws {
        // TODO: EXPAND THIS WITH MORE TYPES OF DATA
        XCTAssertNotNil(webRTCModel.decodeReceivedData(data: filledConnectedUserUUIDData!))
        
        XCTAssertNotNil(webRTCModel.decodeReceivedData(data: toThisUserSDPData[0]!))

        XCTAssertNotNil(webRTCModel.decodeReceivedData(data: user1CandidateData[0]!))
    
        
    }
    
    
    // MARK: RECEIVED CONNECTED USER MESSAGE
    
    // If user receives a JustConnectedUser message, it should update its peerConnections array accordingly
    func testSetFirstPeerConnectionAndSendSDPIfReceivedConnectedUserMessage() async throws {
         
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await webRTCModel.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        // Check to see if results from API were expected
        XCTAssertTrue(webRTCModel.peerConnections[0].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
        
    }
    
    // If there already exists 2 peer connections, peer connections array should be appended with new peer connection
    func testSetPeerConnectionAndSendSDPIfReceivedConnectedUserMessageAndPeersExists() async throws {
        
        let existingPeerConnections = [PeerConnection(receivingAgentsUUID: "FIRSTPEERID1", delegate: webRTCModel),
                                       PeerConnection(receivingAgentsUUID: "SECONDPEERID", delegate: webRTCModel)
                                      ]
        
        // Set: Peerconnections array
        webRTCModel.peerConnections = existingPeerConnections
        
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await webRTCModel.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        XCTAssertTrue(webRTCModel.peerConnections[2].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
    }
    
    
    // If user receives an incorrectly formatted JustConnectedUser message, pC.receivingAgentsUUID should not be updated with such UUID
    func testErrorIfReceivedEmptyConnectedUserMessage() async throws {
        
        // Act: Call API
        await webRTCModel.webSocket(didReceiveData: emptyConnectedUserUUIDData!)
        
        // Check:
        XCTAssertNil(webRTCModel.peerConnections[0].receivingAgentsUUID)
        
    }
    
    // MARK: RECEIVED DISCONNECTED USER MESSAGE
        
    func testErrorIfReceivedEmptyDisconnectedUserMessage() async throws {
        
        // Act: Call my API
        await webRTCModel.webSocket(didReceiveData: emptyDisconnectedUserUUID!)
        
        // Check:
        XCTAssertNil(webRTCModel.peerConnections[0].receivingAgentsUUID)
        
    }
    
    
    // MARK: INTEGRATION TEST | ORDER OF RECEIVING CONNECTION & DISCONNECTION
    
    // This test makes sure that didReceiveData method executes only after all methods executed (inside of it) when the first time it was called is runned (including @escaping closures).
    func testOrderOfDidReceivingConnectionDisconnection() async throws {
        let expectation = XCTestExpectation(description: "Data processed in order")
        expectation.expectedFulfillmentCount = 2

        // Define a variable to track the order of processing
        var lastProcessedData: String?

        // Extend or mock webSocketHandler to add a completion handler
        webRTCModel.processDataCompletion = { data in
            switch data {
            case "Connected User": 
                if lastProcessedData == nil {
                    lastProcessedData = data
                    
                    expectation.fulfill() // Fulfill the first expectation
                }
                
            case "Disconnected User":
                if lastProcessedData == "Connected User" {
                    expectation.fulfill() // Fulfill the second expectation
                }
                 
            default: print("")
            }
        }
        
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        
        await fulfillment(of: [expectation])
    }
    
    // MARK: INTEGRATION TEST | CONNECTING & DISCONNECTING
    
    // This makes sure that a peer connection instance is removed properly everytime they disconnect.
    // It also makes sure that new peer connection instances are added properly to webRTCModel even when the same agent reconnects.
    
    func testReconnectingAfterDisconnecting() async throws {
        let expectation = XCTestExpectation(description: "Data processed in order")
        expectation.expectedFulfillmentCount = 10

        // Extend or mock webSocketHandler to add a completion handler
        webRTCModel.processDataCompletion = { data in
            switch data {
            case "Connected User": expectation.fulfill()
            case "Disconnected User": expectation.fulfill()
            default: print("")
            }
        }
        
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[1]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[2]!)
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await webRTCModel.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[3]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[1]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[2]!)
        await webRTCModel.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[3]!)

        await fulfillment(of: [expectation])
    }
    
    // MARK: INTEGRATION TEST | RECEIVING SDP/CANDIDATE & ANSWERING
    
    // This tests whether the webRTC object can handle when multiple users send offer sdp and candidate information.
    // We see if the answerer can handle multiple simultaneous messages from the connected agents.
    
    func testReceivingSDPAndCandidatesAndAnswering() async throws {
        let expectation = XCTestExpectation(description: "Order of Receiving SDP & Candidates")
        expectation.expectedFulfillmentCount = 19

        try await webRTCModel.signalingClient.connect()
        
        var sdpCount = 0
        var candidateFromUsersCount = [0,0,0,0]
        var answerSDPToUsersCount = [0,0,0,0]
        
        webRTCModel.processDataCompletion = { data in
            print("data: \(String(describing: data.split(separator: " ").first)), H: COUNT:", sdpCount + candidateFromUsersCount.reduce(0, +) + answerSDPToUsersCount.reduce(0, +))
            
            if data == "Received & Set SDP" {
                sdpCount += 1
                expectation.fulfill()
            } else if data.split(separator: " ").first == "Candidate" {
                print("INDEX: \(Int(String(data.last!))! - 1)")
                candidateFromUsersCount[Int(String(data.last!))! - 1] += 1
                expectation.fulfill()
            } else if data.split(separator: " ").first == "Answer" {
                answerSDPToUsersCount[Int(String(data.last!))! - 1] += 1
                expectation.fulfill()
            }
            
        }
        
        await webRTCModel.webSocket(didReceiveData: toThisUserSDPData[0]!)
        await webRTCModel.webSocket(didReceiveData: user1CandidateData[0]!)
        await webRTCModel.webSocket(didReceiveData: user1CandidateData[1]!)
        await webRTCModel.webSocket(didReceiveData: toThisUserSDPData[1]!)
        await webRTCModel.webSocket(didReceiveData: toThisUserSDPData[2]!)
        await webRTCModel.webSocket(didReceiveData: toThisUserSDPData[3]!)
        await webRTCModel.webSocket(didReceiveData: user2CandidateData[0]!)
        await webRTCModel.webSocket(didReceiveData: user1CandidateData[2]!)
        await webRTCModel.webSocket(didReceiveData: user2CandidateData[1]!)
        await webRTCModel.webSocket(didReceiveData: user1CandidateData[3]!)
        await webRTCModel.webSocket(didReceiveData: user3CandidateData[0]!)
        await webRTCModel.webSocket(didReceiveData: user4CandidateData[0]!)
        await webRTCModel.webSocket(didReceiveData: user3CandidateData[1]!)
        await webRTCModel.webSocket(didReceiveData: user1CandidateData[4]!)
        await webRTCModel.webSocket(didReceiveData: user4CandidateData[1]!)
        
        XCTAssertTrue(webRTCModel.peerConnections[0].receivingAgentsUUID == "USER1")
        XCTAssertTrue(webRTCModel.peerConnections[1].receivingAgentsUUID == "USER2")
        XCTAssertTrue(webRTCModel.peerConnections[2].receivingAgentsUUID == "USER3")
        XCTAssertTrue(webRTCModel.peerConnections[3].receivingAgentsUUID == "USER4")

        XCTAssertTrue(sdpCount == 4)
        XCTAssertTrue(candidateFromUsersCount == [5,2,2,2])
        XCTAssertTrue(answerSDPToUsersCount == [1,1,1,1])
        
        await fulfillment(of: [expectation])
        
    }
    
    // MARK: INTEGRATION TEST | DISCONNECT WHILE ATTEMPTING TO SEND ANSWER
    
    
    
    
    // TODO: Create a test to see if other people can handle multiple sdp and candidates from different sources at once.
    
    
    // TODO: MORE TESTS
}
