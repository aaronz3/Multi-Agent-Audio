//
//  PlayViewModelTest.swift
//  PlayViewModelTest
//
//  Created by Aaron Zheng on 1/20/24.
//

import XCTest
import Combine
@testable import AudioGame

final class PlayViewModelTest: XCTestCase {
    
    var playMV: PlayViewModel! = nil
    var websocket: MockNetworkSocket! = nil
    var signalingClient: SignalingClient! = nil
    
    override func setUp() {
        websocket = MockNetworkSocket()
        signalingClient = SignalingClient(url: defaultSignalingServerUrl, websocket: websocket)
        signalingClient.setCurrentUserUUID(uuid: "THISUSER")
        playMV = PlayViewModel(signalingClient: signalingClient)
    }
    
    override func tearDown() {
        playMV = nil
        signalingClient = nil
        websocket = nil
    }

    func testNoPeerConnectionsIfJustInitializedwebRTCMV() {
        XCTAssertTrue(playMV.peerConnections.count == 1)
        XCTAssertNil(playMV.peerConnections[0].receivingAgentsUUID)
    }
    
    func testDecodeUserMessage() throws {
        XCTAssertNotNil(playMV.decodeReceivedData(data: filledConnectedUserUUIDData!))
        
        XCTAssertNotNil(playMV.decodeReceivedData(data: toThisUserSDPOfferData[0]!))

        XCTAssertNotNil(playMV.decodeReceivedData(data: user1CandidateData[0]!))
    }
    
    // MARK: RECEIVED CONNECTED USER MESSAGE
    
    // If user receives a JustConnectedUser message, it should update its peerConnections array accordingly
    func testSetFirstPeerConnectionAndSendSDPIfReceivedConnectedUserMessage() async throws {
         
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await playMV.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        // Check to see if results from API were expected
        XCTAssertTrue(playMV.peerConnections[0].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
        
    }
    
    // If there already exists 2 peer connections, peer connections array should be appended with new peer connection
    func testSetPeerConnectionAndSendSDPIfReceivedConnectedUserMessageAndPeersExists() async throws {
        
        let existingPeerConnections = [PeerConnection(receivingAgentsUUID: "FIRSTPEERID1", delegate: playMV),
                                       PeerConnection(receivingAgentsUUID: "SECONDPEERID", delegate: playMV)
                                      ]
        
        // Set: Peerconnections array
        playMV.peerConnections = existingPeerConnections
        
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await playMV.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        XCTAssertTrue(playMV.peerConnections[2].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
    }
    
    
    // If user receives an incorrectly formatted JustConnectedUser message, pC.receivingAgentsUUID should not be updated with such UUID
    func testErrorIfReceivedEmptyConnectedUserMessage() async throws {
        
        // Act: Call API
        await playMV.webSocket(didReceiveData: emptyConnectedUserUUIDData!)
        
        // Check:
        XCTAssertNil(playMV.peerConnections[0].receivingAgentsUUID)
        
    }
    
    // MARK: RECEIVED DISCONNECTED USER MESSAGE
        
    func testErrorIfReceivedEmptyDisconnectedUserMessage() async throws {
        
        // Act: Call my API
        await playMV.webSocket(didReceiveData: emptyDisconnectedUserUUID!)
        
        // Check:
        XCTAssertNil(playMV.peerConnections[0].receivingAgentsUUID)
        
    }
    
    // MARK: OFFERER RECEIVES ANSWER
    
    func testOffererReceivingSDPFromAnswerer() async throws {
        let expectation = XCTestExpectation(description: "Receive answer")
        expectation.expectedFulfillmentCount = 1
        
        playMV.processDataCompletion = { data in
            switch data {
            case "Received & Set SDP":
                expectation.fulfill()
            default: break
            }
        }
        
        playMV.peerConnections.append(PeerConnection(receivingAgentsUUID: "USER2", delegate: playMV))
        playMV.peerConnections.append(PeerConnection(receivingAgentsUUID: "USER3", delegate: playMV))
        await playMV.webSocket(didReceiveData: filledConnectedUserUUIDData!)
        await playMV.webSocket(didReceiveData: toThisUserSDPAnswerData[0]!)

        await fulfillment(of: [expectation])

        XCTAssertTrue(playMV.peerConnections[0].receivingAgentsUUID == "USER1")
    }
    
        
    // MARK: INTEGRATION TEST | CONNECTING & DISCONNECTING
    
    // This makes sure that a peer connection instance is removed properly everytime they disconnect.
    // It also makes sure that new peer connection instances are added properly to playMV even when the same agent reconnects.
    
    func testReconnectingAfterDisconnecting() async throws {
        let expectation = XCTestExpectation(description: "Data processed in order")
        expectation.expectedFulfillmentCount = 10

        var cancellables: Set<AnyCancellable> = []
        
        playMV.$peerConnections
                .dropFirst()
                .sink { _ in
                    expectation.fulfill()
                }
                .store(in: &cancellables)
        
        await playMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await playMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[1]!)
        await playMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await playMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[2]!)
        await playMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await playMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[3]!)
        await playMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await playMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[1]!)
        await playMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[2]!)
        await playMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[3]!)
        
        await fulfillment(of: [expectation])
        
        XCTAssertTrue(playMV.peerConnections.count == 1)
        XCTAssertNil(playMV.peerConnections[0].receivingAgentsUUID)
    }
    
    // MARK: INTEGRATION TEST | RECEIVING SDP/CANDIDATE & ANSWERING
    
    // This tests whether the webRTC object can handle when multiple users send offer sdp and candidate information.
    // We see if the answerer can handle multiple simultaneous messages from the connected agents.
    
    func testReceivingSDPAndCandidatesAndAnswering() async throws {
        let expectation = XCTestExpectation(description: "Order of Receiving SDP & Candidates")
        expectation.expectedFulfillmentCount = 19

        var previousData = [Int]()
        
        playMV.processDataCompletion = { data in
            if data == "Received & Set SDP" {
                previousData.append(0)
                expectation.fulfill()
            } else if data.split(separator: " ").first == "Candidate" {
                previousData.append(1)
                expectation.fulfill()
            } else if data.split(separator: " ").first == "Answer" {
                previousData.append(2)
                expectation.fulfill()
            }
        }
                
        await playMV.webSocket(didReceiveData: toThisUserSDPOfferData[0]!)
        XCTAssertTrue(playMV.peerConnections[0].receivingAgentsUUID == "USER1")
        await playMV.webSocket(didReceiveData: user1CandidateData[0]!)
        await playMV.webSocket(didReceiveData: user1CandidateData[1]!)
        await playMV.webSocket(didReceiveData: toThisUserSDPOfferData[1]!)
        XCTAssertTrue(playMV.peerConnections[1].receivingAgentsUUID == "USER2")
        await playMV.webSocket(didReceiveData: toThisUserSDPOfferData[2]!)
        XCTAssertTrue(playMV.peerConnections[2].receivingAgentsUUID == "USER3")
        await playMV.webSocket(didReceiveData: toThisUserSDPOfferData[3]!)
        XCTAssertTrue(playMV.peerConnections[3].receivingAgentsUUID == "USER4")
        await playMV.webSocket(didReceiveData: user2CandidateData[0]!)
        await playMV.webSocket(didReceiveData: user1CandidateData[2]!)
        await playMV.webSocket(didReceiveData: user2CandidateData[1]!)
        await playMV.webSocket(didReceiveData: user1CandidateData[3]!)
        await playMV.webSocket(didReceiveData: user3CandidateData[0]!)
        await playMV.webSocket(didReceiveData: user4CandidateData[0]!)
        await playMV.webSocket(didReceiveData: user3CandidateData[1]!)
        await playMV.webSocket(didReceiveData: user1CandidateData[4]!)
        await playMV.webSocket(didReceiveData: user4CandidateData[1]!)
        

        XCTAssertTrue(previousData == [0,1,2,1,0,0,0,1,2,1,1,1,1,2,1,2,1,1,1])
        
        await fulfillment(of: [expectation])
        
    }
    
    // MARK: INTEGRATION TEST | DISCONNECT WHILE ATTEMPTING TO SEND ANSWER
    
    
    
    
    // TODO: Create a test to see if other people can handle multiple sdp and candidates from different sources at once.
    
    
    // TODO: MORE TESTS
}
