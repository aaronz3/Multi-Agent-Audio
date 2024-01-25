//
//  WebRTCClient.swift
//  Audio
//
//  Created by Aaron Zheng on 1/13/24.
//

import Foundation
import WebRTC

protocol PeerConnectionDelegate: AnyObject {
    
    func didDiscoverLocalCandidate(sendToAgent: String, candidate: RTCIceCandidate)
    @MainActor func webRTCClientConnected()
    @MainActor func webRTCClientDisconnected()
}

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
let defaultIceServers = ["stun:stun.l.google.com:19302",
                         "stun:stun1.l.google.com:19302",
                         "stun:stun2.l.google.com:19302",
                         "stun:stun3.l.google.com:19302",
                         "stun:stun4.l.google.com:19302"]

class PeerConnectionFactory {
    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
}

class PeerConnection: NSObject, Identifiable, ObservableObject {
    
    @Published private var peerConnection: RTCPeerConnection
    @Published var receivingAgentsUUID: String?

    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
    
    var returnedSDP: Bool = false
    
    unowned var delegate: PeerConnectionDelegate

    init(receivingAgentsUUID: String?, delegate: PeerConnectionDelegate) {
        
        /* Setup the peerConnection object which will handle the sending and answering of the sdp */
        
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: defaultIceServers)]
                
        config.continualGatheringPolicy = .gatherContinually

        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil,
                                              optionalConstraints: nil)
        
        guard let peerConnection = PeerConnectionFactory.factory.peerConnection(with: config, constraints: constraints, delegate: nil) else {
            fatalError("Could not create new RTCPeerConnection")
        }
        
        self.peerConnection = peerConnection
        
        /* The class that takes this delegate will manage the PeerConnectionDelegate functions */
        
        self.delegate = delegate
        
        /* This PeerConnection instance will only be in charge of one connection */

        self.receivingAgentsUUID = receivingAgentsUUID
        
        /* Setup media steam to send over via SDP and audio session */
        
        super.init()
        self.createMediaSenders()
        self.peerConnection.delegate = self
    }
    
    deinit {
        print("NOTE: Peer connection class has been deinitialized")
        
    }
    
    // Add the audio media stream to be sent over the peer connection object
    func createMediaSenders() {
        let streamId = "stream"
        
        // Audio
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = PeerConnectionFactory.factory.audioSource(with: audioConstraints)
        let audioTrack = PeerConnectionFactory.factory.audioTrack(with: audioSource, trackId: "audio0")

        self.peerConnection.add(audioTrack, streamIds: [streamId])
        
        
    }
    
    // MARK: SIGNALING
    
    func offer() async throws -> RTCSessionDescription {
        
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        
        let sdp = try await self.peerConnection.offer(for: constrains) // If error, then print fails to get offer sdp
        
        try await self.peerConnection.setLocalDescription(sdp)         // If error, then print fails to set sdp
        
        return sdp
    }
    
    func answer() async throws -> RTCSessionDescription {
        let constrains = RTCMediaConstraints(mandatoryConstraints: self.mediaConstrains,
                                             optionalConstraints: nil)
        
        let sdp = try await self.peerConnection.answer(for: constrains) // If error, then print fails to get answer sdp
        
        try await self.peerConnection.setLocalDescription(sdp)          // If error, then print fails to get set sdp
        
        return sdp
    }
    
    // MARK: SET THE SDP AND ADD THE ICE CANDIDATES
    
    func set(remoteSdp: RTCSessionDescription) async throws {
        try await self.peerConnection.setRemoteDescription(remoteSdp)
    }
    
    func set(remoteCandidate: RTCIceCandidate) async throws {
        try await self.peerConnection.add(remoteCandidate)
    }
    
    // MARK: MUTING AND UNMUTING OF AUDIO

    func muteAudio() {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: false)
    }
    
    func unmuteAudio() {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: true)
    }
    
    func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
    
    
}


extension PeerConnection: RTCPeerConnectionDelegate {
   
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        switch stateChanged {
        case .closed:
            print("SIGNALING STATE: \(receivingAgentsUUID) is closed")
        case .stable:
            print("SIGNALING STATE: \(receivingAgentsUUID) is stable")
        case .haveLocalOffer:
            print("SIGNALING STATE: \(receivingAgentsUUID) has local offer")
        case .haveLocalPrAnswer:
            print("SIGNALING STATE: \(receivingAgentsUUID) has local PrAnswer")
        case .haveRemoteOffer:
            print("SIGNALING STATE: \(receivingAgentsUUID) has remote offer")
        case .haveRemotePrAnswer:
            print("SIGNALING STATE: \(receivingAgentsUUID) has remote PrAnswer")
        @unknown default: print("DNE")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        print("NOTE: \(receivingAgentsUUID) added stream")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        print("NOTE: \(receivingAgentsUUID) remove stream")
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("NOTE: peerConnection should negotiate")
    }
    
    @MainActor func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        switch newState {
        case .connected, .completed:
            print("NEW STATE: Connected to agent", receivingAgentsUUID)
            
            self.muteAudio()
            // Turn on the speaker only after two peers have been connected. If you try to turn the speakers on before the peers are connected, the user will need to manually select the speaker button after they have connected.
            
            HandleAudioSession.speakerOn()
            
            self.delegate.webRTCClientConnected()
            
        case .disconnected:
            print("NEW STATE: \(receivingAgentsUUID) disconnected.")
            self.delegate.webRTCClientDisconnected()
            
        case .failed:
            print("NEW STATE: \(receivingAgentsUUID) failed.")
            self.delegate.webRTCClientDisconnected()

        case .closed:
            print("NEW STATE: \(receivingAgentsUUID) closed.")
            self.delegate.webRTCClientDisconnected()

        case .new, .checking, .count:
            print("NEW STATE: \(receivingAgentsUUID) checking.")
            
        @unknown default: print("DNE")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        switch newState {
        case .complete:
            print("NEW GATHERING STATE: \(receivingAgentsUUID) is complete")
        case .new:
            print("NEW GATHERING STATE: \(receivingAgentsUUID) is new")
        case .gathering:
            print("NEW GATHERING STATE: \(receivingAgentsUUID) is gathering")
        @unknown default: print("DNE")
    
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: receivingAgentsUUID is nil")
            return
        }
        
        self.delegate.didDiscoverLocalCandidate(sendToAgent: receivingAgentsUUID, candidate: candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: receivingAgentsUUID is nil")
            return
        }
        
        print("NOTE: \(receivingAgentsUUID) remove \(candidates.count) candidate(s)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("peerConnection did open data channel")
    }
}
