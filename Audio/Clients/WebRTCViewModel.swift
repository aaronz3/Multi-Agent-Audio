//
//  WebRTCViewModel.swift
//  Audio
//
//  Created by Aaron Zheng on 1/14/24.
//

import Foundation
import WebRTC

//@Observable
class WebRTCViewModel: WebSocketProviderDelegate, PeerConnectionDelegate, ObservableObject {
    
    @Published var peerConnections: [PeerConnection] = []
    var signalingClient: SignalingClient
    
    @Published var signalingConnected = false
    @Published var disableTalkButton = true
        
    // TODO: Only for testing purposes
    var processDataCompletion: ((String) -> ())?
    
    init(signalingClient: SignalingClient) {
        self.signalingClient = signalingClient
        self.signalingClient.delegate = self
        
        let peer = PeerConnection(receivingAgentsUUID: nil, delegate: self)
        
        self.peerConnections.append(peer)
        
    }
    
    // MARK: WebSocketProviderDelegate PROTOCOL FUNCTIONS
    
    func webSocketDidConnect() {
        print("NOTE: Attempted to connect websocket.")
        DispatchQueue.main.async {
            self.signalingConnected = true
        }
    }
    
    func webSocketDidDisconnect() {
        print("NOTE: Websocket disconnected (executed from protocol)")
        self.resetPeerConnections()
    }
    
    func webSocket(didReceiveData data: Data) async {
        
        guard self.peerConnections.first != nil else {
            print("DEBUG: Peer connections is nil here")
            return
        }
        switch self.decodeReceivedData(data: data) {
            
        case .candidate(let iceCandidate): await self.receivedCandidate(iceCandidate: iceCandidate)
            
        case .sdp(let sessionDescription): await self.receivedSDP(sessionDescription: sessionDescription)
            
            // Runs when some other user connects to the signaling server. The server relays the other user's information to you.
        case .justConnectedUser(let justConnectedUser): await self.receivedConnectedUser(justConnectedUser: justConnectedUser)
            
        case .justDisconnectedUser(let disconnectedUser): await self.receivedDisconnectedUser(disconnectedUser: disconnectedUser)
            
        default :
            print("DEBUG: Got an unknown message.")
            
        }
    }
    
    func decodeReceivedData(data: Data) -> Message? {
        do {
            let returnMessage = try self.signalingClient.decoder.decode(Message.self, from: data)
            return returnMessage
        } catch {
            print("DEBUG: Error in decodeReceivedData. \(error.localizedDescription)")
            return nil
        }
    }
    
    func receivedCandidate(iceCandidate: IceCandidate) async {
        for pC in self.peerConnections {
            
            guard pC.receivingAgentsUUID == iceCandidate.fromUUID else {
                continue
            }
            
            do {
                try await pC.set(remoteCandidate: iceCandidate.rtcIceCandidate)
                
                // TODO: Only for testing purposes
                self.processDataCompletion?("Candidate \(iceCandidate.fromUUID)")
                
                // Check to see if agent has already sent an answer sdp in the past.
                // If so, do not send another answer sdp and do not continue running for loop
                guard !pC.returnedSDP else {
                    return
                }
                
                pC.returnedSDP = true
                
                // If a disconnection occurs before this block runs, exit this block.
                // If peer connection does not exist anymore (this implies the offerer has disconnected), then we do not want to answer.
                guard self.signalingClient.webSocket != nil && pC.receivingAgentsUUID != nil else {
                    print("NOTE: Websocket has been disconnected or the other user disconnected")
                    return
                }
                
                let sdp = try await pC.answer()
                
                await self.signalingClient.send(toUUID: iceCandidate.fromUUID, message: .sdp(sdp))
                
                // TODO: Only for testing purposes
                self.processDataCompletion?("Answer \(iceCandidate.fromUUID)")
                
            } catch {
                print("DEBUG: Error in receivedCandidate. \(error.localizedDescription)")
            }
            
        }
    }
    
    // TODO: TEST THIS
    func receivedSDP(sessionDescription: SessionDescription) async {
        
        guard self.signalingClient.webSocket != nil else {
            print("DEBUG: Websocket is nil")
            return
        }
        
        let allReceivingAgentsUUID = self.returnAllReceivingAgentsUUID()
        
        do {
            // This is for the answerer that has not gotten the UUID of an offerer when he has not gotten any offers
            if self.peerConnections[0].receivingAgentsUUID == nil {
                
                await MainActor.run {
                    self.peerConnections[0].receivingAgentsUUID = sessionDescription.fromUUID
                }
                
                try await self.peerConnections[0].set(remoteSdp: sessionDescription.rtcSessionDescription)
                
            // This is for the answerer that has not gotten the UUID of an offerer when he already has offers.
            } else if !allReceivingAgentsUUID.contains(where: { sessionDescription.fromUUID == $0 }) {
                let pC = PeerConnection(receivingAgentsUUID: sessionDescription.fromUUID, delegate: self)
                
                await MainActor.run {
                    self.peerConnections.append(pC)
                }
                
                try await pC.set(remoteSdp: sessionDescription.rtcSessionDescription)
                
            // This for the offerer that already set the receivingAgentsUUID when it got the UUID of the just connected user.
            } else if allReceivingAgentsUUID.contains(where: { sessionDescription.fromUUID == $0 }) {
                
                for pC in self.peerConnections {
                    guard pC.receivingAgentsUUID == sessionDescription.fromUUID else {
                        continue
                    }
                    try await pC.set(remoteSdp: sessionDescription.rtcSessionDescription)
                    
                    break
                }
                
            } else {
                print("DEBUG: UUID fell through everything")
                return
            }
            
            // TODO: Only for testing purposes
            self.processDataCompletion?("Received & Set SDP")
            
            print("SUCCESS: Received and set offer/answer sdp from", sessionDescription.fromUUID)
            print("NOTE: There are \(self.peerConnections.count) peer connection instances")
            
        } catch {
            print("DEBUG: Error in receivedSDP for \(sessionDescription.fromUUID). \(error.localizedDescription)")
        }
        
    }
    
    func receivedConnectedUser(justConnectedUser: JustConnectedUser) async {
        
        // Gather the UUIDs of all PeerConnection objects to see if any have the same UUID.
        let allReceivingAgentsUUID = self.returnAllReceivingAgentsUUID()
        do {
            // This is for the offerer whose first connected user is the incoming user
            if self.peerConnections[0].receivingAgentsUUID == nil {
                
                await MainActor.run {
                    self.peerConnections[0].receivingAgentsUUID = justConnectedUser.userUUID
                }
                
                let sdp = try await self.peerConnections[0].offer()
                
                await self.signalingClient.send(toUUID: justConnectedUser.userUUID, message: .sdp(sdp))
                
                self.peerConnections[0].returnedSDP = true
                
                // This is for the offerer who already connected with other agents.
            } else if !allReceivingAgentsUUID.contains(where: { justConnectedUser.userUUID == $0 }) {
                let pC = PeerConnection(receivingAgentsUUID: justConnectedUser.userUUID, delegate: self)
                
                await MainActor.run {
                    self.peerConnections.append(pC)
                }
                
                let sdp = try await pC.offer()
                
                await self.signalingClient.send(toUUID: justConnectedUser.userUUID, message: .sdp(sdp))
                
                self.peerConnections[0].returnedSDP = true
                
            } else {
                print("DEBUG: Fell through everything")
                return
            }
            
            print("SUCCESS: Received UUID from \(justConnectedUser.userUUID) and OFFERED sdp")
            print("NOTE: There are \(self.peerConnections.count) peer connection instances")
            
        } catch {
            print("DEBUG: Error in receivedConnectedUser. \(error.localizedDescription)")
        }
        
    }
    
    
    func receivedDisconnectedUser(disconnectedUser: DisconnectedUser) async {
        
        // This is for the offerer who has only one connection
        if self.peerConnections.count == 1 {
            
            let peer = PeerConnection(receivingAgentsUUID: nil, delegate: self)
            
            await MainActor.run {
                self.peerConnections.append(peer)
                self.disableTalkButton = true
            }
            
            print("NOTE: Sucessfully removed and appended new peer connection instance. There are \(self.peerConnections.count) peerconnection instances")
            
        }
        
        await MainActor.run {
            self.peerConnections.removeAll { pC in
                pC.receivingAgentsUUID == disconnectedUser.userUUID
            }
        }
        
    }
    
    func returnAllReceivingAgentsUUID() -> [String] {
        var allReceivingAgentsUUID: [String] = []
        for pC in self.peerConnections {
            if let uuid = pC.receivingAgentsUUID {
                allReceivingAgentsUUID.append(uuid)
            }
        }
        return allReceivingAgentsUUID
    }
    
    func resetPeerConnections() {
        DispatchQueue.main.async {
            if !self.peerConnections.isEmpty {
                self.peerConnections = []
                
                let peer = PeerConnection(receivingAgentsUUID: nil, delegate: self)
                self.peerConnections.append(peer)
                
                self.signalingConnected = false
                print("SUCCESS: Peer connections reset")
            }
        }
    }
    
    // MARK: PeerConnectionDelegate PROTOCOL FUNCTIONS
    
    func didDiscoverLocalCandidate(sendToAgent: String, candidate: RTCIceCandidate) {
        print("NOTE: Discovered local candidate. Send candidate to: \(sendToAgent).")
        Task {
            await self.signalingClient.send(toUUID: sendToAgent, message: .candidate(candidate))
        }
    }
    
    
    func webRTCClientConnected() {
        print("NOTE: Enabled talk button since connected")
        DispatchQueue.main.async {
            self.disableTalkButton = false
        }
        
    }
    
    func webRTCClientDisconnected() {
        print("NOTE: Disabled talk button since disconnected")
        if self.peerConnections.first?.receivingAgentsUUID == nil {
            DispatchQueue.main.async {
                self.disableTalkButton = true
            }
        }
    }
    
    // MARK: MUTING AND UNMUTING OF PEERCONNECTION INSTANCES
    
    func muteAudio() {
        for pC in self.peerConnections {
            pC.muteAudio()
        }
    }
    
    func unmuteAudio() {
        
        print("NOTE: Unmuted audio. There are \(self.peerConnections.count) peer connections")
        
        for pC in self.peerConnections {
            print("One receiving agent's UUID is", pC.receivingAgentsUUID ?? "nil")
            pC.unmuteAudio()
        }
    }
    
}