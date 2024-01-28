//
//  WebRTCViewModelTest.swift
//  WebRTCViewModelTest
//
//  Created by Aaron Zheng on 1/20/24.
//

import XCTest
import Combine
@testable import Audio

final class WebRTCViewModelTest: XCTestCase {
    
    var webRTCMV: WebRTCViewModel! = nil
    var websocket: MockNetworkSocket! = nil
    var signalingClient: SignalingClient! = nil
    
    override func setUp() {
        websocket = MockNetworkSocket()
        signalingClient = SignalingClient(url: defaultSignalingServerUrl, currentUserUUID: "THISUSER", websocket: websocket)
        webRTCMV = WebRTCViewModel(signalingClient: signalingClient)
    }
    
    override func tearDown() {
        webRTCMV = nil
        signalingClient = nil
        websocket = nil
    }

    func testNoPeerConnectionsIfJustInitializedwebRTCMV() {
        XCTAssertTrue(webRTCMV.peerConnections.count == 1)
        XCTAssertNil(webRTCMV.peerConnections[0].receivingAgentsUUID)
    }
    
    func testDecodeUserMessage() throws {
        XCTAssertNotNil(webRTCMV.decodeReceivedData(data: filledConnectedUserUUIDData!))
        
        XCTAssertNotNil(webRTCMV.decodeReceivedData(data: toThisUserSDPOfferData[0]!))

        XCTAssertNotNil(webRTCMV.decodeReceivedData(data: user1CandidateData[0]!))
    }
    
    // MARK: RECEIVED CONNECTED USER MESSAGE
    
    // If user receives a JustConnectedUser message, it should update its peerConnections array accordingly
    func testSetFirstPeerConnectionAndSendSDPIfReceivedConnectedUserMessage() async throws {
         
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await webRTCMV.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        // Check to see if results from API were expected
        XCTAssertTrue(webRTCMV.peerConnections[0].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
        
    }
    
    // If there already exists 2 peer connections, peer connections array should be appended with new peer connection
    func testSetPeerConnectionAndSendSDPIfReceivedConnectedUserMessageAndPeersExists() async throws {
        
        let existingPeerConnections = [PeerConnection(receivingAgentsUUID: "FIRSTPEERID1", delegate: webRTCMV),
                                       PeerConnection(receivingAgentsUUID: "SECONDPEERID", delegate: webRTCMV)
                                      ]
        
        // Set: Peerconnections array
        webRTCMV.peerConnections = existingPeerConnections
        
        // Act: Call my API, using the filledJustConnectedUserObject created in the TestData.swift file.
        await webRTCMV.receivedConnectedUser(justConnectedUser: filledJustConnectedUserObject)
        
        XCTAssertTrue(webRTCMV.peerConnections[2].receivingAgentsUUID == "BF73C8CF-8176-4E76-952B-3A20CD2EB21D")
    }
    
    
    // If user receives an incorrectly formatted JustConnectedUser message, pC.receivingAgentsUUID should not be updated with such UUID
    func testErrorIfReceivedEmptyConnectedUserMessage() async throws {
        
        // Act: Call API
        await webRTCMV.webSocket(didReceiveData: emptyConnectedUserUUIDData!)
        
        // Check:
        XCTAssertNil(webRTCMV.peerConnections[0].receivingAgentsUUID)
        
    }
    
    // MARK: RECEIVED DISCONNECTED USER MESSAGE
        
    func testErrorIfReceivedEmptyDisconnectedUserMessage() async throws {
        
        // Act: Call my API
        await webRTCMV.webSocket(didReceiveData: emptyDisconnectedUserUUID!)
        
        // Check:
        XCTAssertNil(webRTCMV.peerConnections[0].receivingAgentsUUID)
        
    }
    
    // MARK: OFFERER RECEIVES ANSWER
    
    func testOffererReceivingSDPFromAnswerer() async throws {
        let expectation = XCTestExpectation(description: "Receive answer")
        expectation.expectedFulfillmentCount = 1
        
        webRTCMV.processDataCompletion = { data in
            switch data {
            case "Received & Set SDP":
                expectation.fulfill()
            default: break
            }
        }
        
        webRTCMV.peerConnections.append(PeerConnection(receivingAgentsUUID: "USER2", delegate: webRTCMV))
        webRTCMV.peerConnections.append(PeerConnection(receivingAgentsUUID: "USER3", delegate: webRTCMV))
        await webRTCMV.webSocket(didReceiveData: filledConnectedUserUUIDData!)
        await webRTCMV.webSocket(didReceiveData: toThisUserSDPAnswerData[0]!)

        await fulfillment(of: [expectation])

        XCTAssertTrue(webRTCMV.peerConnections[0].receivingAgentsUUID == "USER1")
    }
    
        
    // MARK: INTEGRATION TEST | CONNECTING & DISCONNECTING
    
    // This makes sure that a peer connection instance is removed properly everytime they disconnect.
    // It also makes sure that new peer connection instances are added properly to webRTCMV even when the same agent reconnects.
    
    func testReconnectingAfterDisconnecting() async throws {
        let expectation = XCTestExpectation(description: "Data processed in order")
        expectation.expectedFulfillmentCount = 10

        var cancellables: Set<AnyCancellable> = []
        
        webRTCMV.$peerConnections
                .dropFirst()
                .sink { _ in
                    expectation.fulfill()
                }
                .store(in: &cancellables)
        
        await webRTCMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await webRTCMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[1]!)
        await webRTCMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await webRTCMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[2]!)
        await webRTCMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[0]!)
        await webRTCMV.webSocket(didReceiveData: filledJustConnectedUserUUIDDataArray[3]!)
        await webRTCMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[0]!)
        await webRTCMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[1]!)
        await webRTCMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[2]!)
        await webRTCMV.webSocket(didReceiveData: filledJustDisconnectedUserUUIDDataArray[3]!)
        
        await fulfillment(of: [expectation])
        
        XCTAssertTrue(webRTCMV.peerConnections.count == 1)
        XCTAssertNil(webRTCMV.peerConnections[0].receivingAgentsUUID)
    }
    
    // MARK: INTEGRATION TEST | RECEIVING SDP/CANDIDATE & ANSWERING
    
    // This tests whether the webRTC object can handle when multiple users send offer sdp and candidate information.
    // We see if the answerer can handle multiple simultaneous messages from the connected agents.
    
    func testReceivingSDPAndCandidatesAndAnswering() async throws {
        let expectation = XCTestExpectation(description: "Order of Receiving SDP & Candidates")
        expectation.expectedFulfillmentCount = 19

        var previousData = [Int]()
        
        webRTCMV.processDataCompletion = { data in
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
                
        await webRTCMV.webSocket(didReceiveData: toThisUserSDPOfferData[0]!)
        XCTAssertTrue(webRTCMV.peerConnections[0].receivingAgentsUUID == "USER1")
        await webRTCMV.webSocket(didReceiveData: user1CandidateData[0]!)
        await webRTCMV.webSocket(didReceiveData: user1CandidateData[1]!)
        await webRTCMV.webSocket(didReceiveData: toThisUserSDPOfferData[1]!)
        XCTAssertTrue(webRTCMV.peerConnections[1].receivingAgentsUUID == "USER2")
        await webRTCMV.webSocket(didReceiveData: toThisUserSDPOfferData[2]!)
        XCTAssertTrue(webRTCMV.peerConnections[2].receivingAgentsUUID == "USER3")
        await webRTCMV.webSocket(didReceiveData: toThisUserSDPOfferData[3]!)
        XCTAssertTrue(webRTCMV.peerConnections[3].receivingAgentsUUID == "USER4")
        await webRTCMV.webSocket(didReceiveData: user2CandidateData[0]!)
        await webRTCMV.webSocket(didReceiveData: user1CandidateData[2]!)
        await webRTCMV.webSocket(didReceiveData: user2CandidateData[1]!)
        await webRTCMV.webSocket(didReceiveData: user1CandidateData[3]!)
        await webRTCMV.webSocket(didReceiveData: user3CandidateData[0]!)
        await webRTCMV.webSocket(didReceiveData: user4CandidateData[0]!)
        await webRTCMV.webSocket(didReceiveData: user3CandidateData[1]!)
        await webRTCMV.webSocket(didReceiveData: user1CandidateData[4]!)
        await webRTCMV.webSocket(didReceiveData: user4CandidateData[1]!)
        

        XCTAssertTrue(previousData == [0,1,2,1,0,0,0,1,2,1,1,1,1,2,1,2,1,1,1])
        
        await fulfillment(of: [expectation])
        
    }
    
    // MARK: INTEGRATION TEST | DISCONNECT WHILE ATTEMPTING TO SEND ANSWER
    
    
    
    
    // TODO: Create a test to see if other people can handle multiple sdp and candidates from different sources at once.
    
    
    // TODO: MORE TESTS
}
