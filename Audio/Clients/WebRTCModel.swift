//
//  ViewModel.swift
//  Audio
//
//  Created by Aaron Zheng on 1/14/24.
//

import Foundation
import WebRTC

let dataProcessingQueue = DispatchQueue(label: "Data Processing Queue")

//@Observable
class WebRTCModel: WebSocketProviderDelegate, PeerConnectionDelegate, ObservableObject {
            
    @Published var peerConnections: [PeerConnection] = []
    var signalingClient: SignalingClient = SignalingClient(url: defaultSignalingServerUrl)

    @Published var signalingConnected = false
    @Published var disableTalkButton = true
    
    
    private let semaphore = DispatchSemaphore(value: 0)

    // TODO: Only for testing purposes
    var processDataCompletion: ((String) -> ())?

    init() {
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
    
    func webSocket(didReceiveData data: Data) {
        
        dataProcessingQueue.sync {
            print("NOTE: Procesing data thread: \(Thread.current)")
            
            guard self.peerConnections.first != nil else {
                print("DEBUG: Peer connections is nil here")
                return
            }
            
            switch self.decodeReceivedData(data: data) {
            
            case .candidate(let iceCandidate): self.receivedCandidate(iceCandidate: iceCandidate)
                
            case .sdp(let sessionDescription): self.receivedSDP(sessionDescription: sessionDescription)
            
            // Runs when some other user connects to the signaling server. The server relays the other user's information to you.
            case .justConnectedUser(let justConnectedUser): self.receivedConnectedUser(justConnectedUser: justConnectedUser)
                
            case .justDisconnectedUser(let disconnectedUser): self.receivedDisconnectedUser(disconnectedUser: disconnectedUser)
                
            default :
                print("DEBUG: Got an unknown message.")
                
            }
        }
    }
    
    func decodeReceivedData(data: Data) -> Message? {
        do {
            let returnMessage = try self.signalingClient.decoder.decode(Message.self, from: data)
            return returnMessage
        }
        catch {
            print("DEBUG: \(error.localizedDescription)")
            return nil
        }
    }
    
    func receivedCandidate(iceCandidate: IceCandidate) {
        for pC in self.peerConnections {
            if pC.receivingAgentsUUID == iceCandidate.fromUUID {
                
                pC.set(remoteCandidate: iceCandidate.rtcIceCandidate) { error in
                    guard error == nil else {
                        print("DEBUG: Error with setting remote candidate. Local Description:", error!.localizedDescription)
                        return
                    }
                    
                    print("SUCCESS: Set \(iceCandidate.fromUUID) remote candidate")
                    
                    
                    // TODO: Only for testing purposes
                    self.processDataCompletion?("Candidate \(iceCandidate.fromUUID)")

                    
                    if !pC.returnedSDP {
                        
                        pC.returnedSDP = true
                        
                        print("NOTE: Sending answer to", iceCandidate.fromUUID)
                        
                        // If a disconnection occurs before this block runs, exit this block.
                        guard self.signalingClient.webSocket != nil else {
                            print("NOTE: Websocket has been disconnected")
                            return
                        }
                        
                        // Guard against if peer connection does not exist anymore. We do not want to answer if the offerer has disconnected.
                        guard pC.receivingAgentsUUID != nil else {
                            print("NOTE: The other user disconnected")
                            return
                        }
                        
                        pC.answer { sdp in
                            self.signalingClient.send(toUUID: iceCandidate.fromUUID, message: .sdp(sdp))
                            print("SUCCESS: Sent the answer to \(iceCandidate.fromUUID)")
                            
                            self.processDataCompletion?("Answer \(iceCandidate.fromUUID)")

                        }
                    }
                    
                }
                
                
            }
        }
    }
    
    // TODO: TEST THIS
    func receivedSDP(sessionDescription: SessionDescription) {
        
        let allReceivingAgentsUUID = self.returnAllReceivingAgentsUUID()
        let pC: PeerConnection?
        
        // This is for the answerer that has not gotten the UUID of an offerer when he has not gotten any offers
        if self.peerConnections[0].receivingAgentsUUID == nil {
            
            pC = peerConnections[0]
            pC!.receivingAgentsUUID = sessionDescription.fromUUID
            
        // This is for the answerer that has not gotten the UUID of an offerer when he already has offers.
        } else if !allReceivingAgentsUUID.contains(where: { sessionDescription.fromUUID == $0 }) {
            
            pC = PeerConnection(receivingAgentsUUID: sessionDescription.fromUUID, delegate: self)
            self.peerConnections.append(pC!)
            
        // This for the offerer that already set the receivingAgentsUUID when it got the UUID of the just connected user.
        } else if allReceivingAgentsUUID.contains(where: { sessionDescription.fromUUID == $0 }) {
            var pCInner: PeerConnection? = nil
            for pCInLoop in self.peerConnections {
                if pCInLoop.receivingAgentsUUID == sessionDescription.fromUUID {
                    pCInner = pCInLoop
                    break
                }
            }
            
            pC = pCInner
            
        } else {
            print("DEBUG: UUID fell through everything")
            return
        }
        
        if let pC = pC {
            pC.set(remoteSdp: sessionDescription.rtcSessionDescription) { [weak webSocket = signalingClient.webSocket] (error) in
                
                guard webSocket != nil else {
                    print("DEBUG: Websocket is nil")
                    return
                }
                
                guard error == nil else {
                    print("DEBUG: Failed in setting sdp.", error!.localizedDescription)
                    return
                }
                
                print("SUCCESS: Received and set offer/answer sdp from", sessionDescription.fromUUID)
                
                // TODO: Only for testing purposes
                self.processDataCompletion?("Received & Set SDP")
                
                self.semaphore.signal()
                
                
                
            }
        }
        
        semaphore.wait()
        
        print("NOTE: There are \(self.peerConnections.count) peer connection instances")

    }
    
    func receivedConnectedUser(justConnectedUser: JustConnectedUser) {
        
        // Gather the UUIDs of all PeerConnection objects to see if any have the same UUID.
        let allReceivingAgentsUUID = self.returnAllReceivingAgentsUUID()
        let pC: PeerConnection
        
        if self.peerConnections[0].receivingAgentsUUID == nil {
            
            pC = self.peerConnections[0]
            pC.receivingAgentsUUID = justConnectedUser.userUUID
            
        } else if !allReceivingAgentsUUID.contains(where: { justConnectedUser.userUUID == $0 }) {
            
            pC = PeerConnection(receivingAgentsUUID: justConnectedUser.userUUID, delegate: self)
            self.peerConnections.append(pC)
            
            print("NOTE: There are \(self.peerConnections.count) peer connection instances")
            
        } else {
            print("DEBUG: Fell through everything")
            return
        }
        
        pC.offer { sdp in
            
            print("NOTE: Thread when made sdp offer: \(Thread.current)")
            
            self.signalingClient.send(toUUID: justConnectedUser.userUUID, message: .sdp(sdp))

            // TODO: Only for testing purposes
            self.processDataCompletion?("Connected User")
            
            self.semaphore.signal()
        }
        
        // This stops dataProcessingQueue from continuing until semaphore.signal() executes.
        semaphore.wait()
        
        pC.returnedSDP = true
        
        print("SUCCESS: Received UUID from \(justConnectedUser.userUUID) and OFFERED sdp")
        print("NOTE: There are \(self.peerConnections.count) peer connection instances")

    }
    
    
    func receivedDisconnectedUser(disconnectedUser: DisconnectedUser) {
        print("NOTE: Thread when inside disconnection: \(Thread.current)")
        
        if self.peerConnections.count == 1 {

            self.peerConnections.removeAll { pC in
                pC.receivingAgentsUUID == disconnectedUser.userUUID
            }
            
            let peer = PeerConnection(receivingAgentsUUID: nil, delegate: self)
            self.peerConnections.append(peer)
            
            self.disableTalkButton = true
            
            print("NOTE: Sucessfully removed and appended new peer connection instance. There are \(self.peerConnections.count) peerconnection instances")
            
            // TODO: Only for testing purposes
            self.processDataCompletion?("Disconnected User")
            
        } else {

            // TODO: TEST THIS
            self.peerConnections.removeAll { pC in
                pC.receivingAgentsUUID == disconnectedUser.userUUID
            }
            
            // TODO: Only for testing purposes
            self.processDataCompletion?("Disconnected User")

            
            
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
        self.signalingClient.send(toUUID: sendToAgent, message: .candidate(candidate))
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
