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
    func didReceiveData()
    func webRTCClientConnected()
    func webRTCClientDisconnected()
    
}

class PeerConnectionFactory {
    static let factory: RTCPeerConnectionFactory = {
        RTCInitializeSSL()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
    }()
}

//@Observable
class PeerConnection: NSObject, Identifiable, ObservableObject {
    
    @Published var receivingAgentsUUID: String?
    @Published var receivingAudioLevel: Float = 0.0
    
    private var peerConnection: RTCPeerConnection
    private let mediaConstrains = [kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue]
    private var remoteDataChannel: RTCDataChannel?
    // Although this property seems useless, it is needed in order to send data.
    private var localDataChannel: RTCDataChannel?
    private var monitorAudio = MonitorAudio()
    
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
        
        do {
            try monitorAudio.setupAudioRecorder()
        } catch {
            print("DEBUG: Setup audio recorder was not possible")
        }
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

        // Data
        if let dataChannel = createDataChannel() {
            dataChannel.delegate = self
            self.localDataChannel = dataChannel
        }
    }
    
    // Create the data channel and provide it to the peer connection instance
    func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        
        guard let dataChannel = self.peerConnection.dataChannel(forLabel: "WebRTCData", configuration: config) else {
            debugPrint("Warning: Couldn't create data channel.")
            return nil
        }
        return dataChannel
    }
    
    func sendData(_ data: Data) {
        print("NOTE: Sent audio level data")
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        self.remoteDataChannel?.sendData(buffer)
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
        
        do {
            try monitorAudio.stopMonitoringAudioLevel { [weak self] in
                self?.sendData("stop".data(using: .utf8)!)
            }
        } catch {
            print("DEBUG: Unable to stop monitoring audio level \(error.localizedDescription)")
        }
    }
    
    func unmuteAudio() {
        setTrackEnabled(RTCAudioTrack.self, isEnabled: true)
        
        do {
            try monitorAudio.startMonitoringAudioLevel { [weak self] audioLevel in
                self?.sendData("\(audioLevel)".data(using: .utf8)!)
            }
        } catch {
            print("DEBUG: Unable to stop monitoring audio level \(error.localizedDescription)")
        }
        
    }
    
    func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, isEnabled: Bool) {
        peerConnection.transceivers
            .compactMap { $0.sender.track as? T }
            .forEach { mediaStreamTrack in
                mediaStreamTrack.isEnabled = isEnabled
            }
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
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        guard let receivingAgentsUUID = self.receivingAgentsUUID else {
            print("DEBUG: ReceivingAgentsUUID is nil, but state changed")
            return
        }
        
        switch newState {
        case .connected, .completed:
            print("NEW STATE: Connected to agent", receivingAgentsUUID)
            
            // Turn on the speaker only after two peers have been connected. If you try to turn the speakers on before the peers are connected, the user will need to manually select the speaker button after they have connected.
            self.muteAudio()
            
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
        print("NOTE: PeerConnection did open data channel")
        self.remoteDataChannel = dataChannel
    }
}

extension PeerConnection: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("NOTE: DataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        
        guard let stringAudioLevel = String(data: buffer.data, encoding: .utf8) else { return }
        
        if stringAudioLevel == "stop" {
            
            receivingAudioLevel = 0.0
            
        } else {
            let floatAudioLevel = (stringAudioLevel as NSString).floatValue
            
            DispatchQueue.main.async {
                self.receivingAudioLevel = floatAudioLevel
                print("NOTE: receivingAudioLevel is \(self.receivingAudioLevel)")
            }
        }
            
        delegate.didReceiveData()

    }
}

