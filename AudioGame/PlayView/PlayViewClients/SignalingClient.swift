//
//  SignalingClient.swift
//  Audio
//
//  Created by Aaron Zheng on 1/8/24.
//

import Foundation
import WebRTC
import Network

protocol WebSocketProviderDelegate: AnyObject {
    func webSocketDidConnect()
    func webSocketDidDisconnect()
    func webSocket(didReceiveData data: Data) async
}

enum SendMessageType {
    case sdp(RTCSessionDescription)
    case candidate(RTCIceCandidate)
    case justConnectedUser(String)
    case disconnectedUser(String)
}

class SignalingClient: NSObject {
    
    let url: URL
    var currentUserUUID: String
    var webSocket: NetworkSocket?
    
    var delegate: WebSocketProviderDelegate?

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    init(url: URL, currentUserUUID: String, websocket: NetworkSocket? = nil) {
        
        // Create url components to send the current agent's uuid to the server
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        // Create a query item and append it to url components
        let queryItemUUID = URLQueryItem(name: "uuid", value: currentUserUUID)
        components.queryItems = [queryItemUUID]
        
        self.currentUserUUID = currentUserUUID
        self.url = components.url!
        super.init()
        
        handleWebsocketForTesting(websocket: websocket)
    }
    
    deinit {
        print("NOTE: Signaling Client deinitialized")
    }
    
    func handleWebsocketForTesting(websocket: NetworkSocket?) {
        // For testing use the injected fake websocket
        if let webSocketTask = websocket {
            self.webSocket = webSocketTask
        
        // For production use the real websocket
        } else {
            let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
            self.webSocket = session.webSocketTask(with: url)
        }
    }
    
    func connect(websocket: NetworkSocket? = nil) async throws {
        
        handleWebsocketForTesting(websocket: websocket)
        
        self.webSocket?.resume()
                
        // Send the "JustConnectedUser" message to the server
        try await self.send(toUUID: nil, message: .justConnectedUser(self.currentUserUUID))
        
        // Alert the data model that a websocket connection has been established
        self.delegate?.webSocketDidConnect()
        
        // Start receiving messages from the server in a separate task
        Task {
            try await self.readMessage()
        }
    }
    
    
    func readMessage() async throws {
        do {
            let message = try await self.webSocket?.receive()
            
            switch message {
            case .data(let data):
                await self.delegate?.webSocket(didReceiveData: data)
                
                try await readMessage() // recursively calling readMessage
                
            case .string(let string):
                print("DEBUG: Got string", string)
                
            default:
                print("DEBUG: Got some unknown message format: \(String(describing: message))")
            }
            
        } catch {
            print("DEBUG: Error in readMessage block.", error.localizedDescription)
            throw URLError(.unknown)
        }
        
    }
    
    func send(toUUID: String?, message: SendMessageType) async throws {
        
        var sendMessageContext: WebRTCMessage
        var printMessageType: String
        
        switch message {
        case .sdp(let sdp):
            guard let toUUID else {
                print("DEBUG: No final destination user id")
                throw URLError(.unknown)
            }
            
            sendMessageContext = WebRTCMessage.sdp(SessionDescription(fromUUID: self.currentUserUUID, toUUID: toUUID, data: sdp))
            printMessageType = "SDP"
            
        case .candidate(let iceCandidate):
            guard let toUUID else {
                print("DEBUG: No final destination user id")
                throw URLError(.unknown)
            }
            
            sendMessageContext = WebRTCMessage.candidate(IceCandidate(fromUUID: self.currentUserUUID, toUUID: toUUID, from: iceCandidate))
            printMessageType = "candidate"
            
        case .justConnectedUser(let uuid):
            
            sendMessageContext = WebRTCMessage.justConnectedUser(JustConnectedUser(userUUID: uuid))
            printMessageType = "current connected agent's UUID"
            
        case .disconnectedUser(let uuid) :
            
            sendMessageContext = WebRTCMessage.justDisconnectedUser(DisconnectedUser(userUUID: uuid))
            printMessageType = "current disconnected agent's UUID"
        }
        
        try await encodeToSend(sendMessageContext: sendMessageContext, printMessageType: printMessageType)
    }
    
    
    func encodeToSend(sendMessageContext: WebRTCMessage, printMessageType: String) async throws {
        let dataMessage = try self.encoder.encode(sendMessageContext)
        
        guard self.webSocket != nil else {
            print("NOTE: Websocket object in signaling class is nil.")
            throw URLError(.badServerResponse)
        }
        
        try await self.webSocket?.send(.data(dataMessage))
        
        print("SUCCESS: Successfully sent \(printMessageType)")
    }
    
    func disconnect() {
        
        self.webSocket?.cancel(with: .normalClosure, reason: nil)
        self.webSocket = nil
        
        self.delegate?.webSocketDidDisconnect()
        
    }
    
}

extension SignalingClient: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("NOTE: Websocket closed by websocket delegate. Reason:", closeCode.description)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        guard let error = error as NSError? else {
            return
        }
        
        // Check if user has internet.
        if error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost {
            print("NOTE: Network connection lost")
        }
        
        // Handle the "Socket is not connected" error
        if error.domain == NSPOSIXErrorDomain && error.code == 57 {
            print("NOTE: Socket is not connected")
        }
        
        self.disconnect()
    }
    
}

extension URLSessionWebSocketTask.CloseCode {
    var description: String {
        switch self {
        case .invalid: return "invalid"
        case .normalClosure: return "normalClosure"
        case .goingAway: return "goingAway"
        case .protocolError: return "protocolError"
        case .unsupportedData: return "unsupportedData"
        case .noStatusReceived: return "noStatusReceived"
        case .abnormalClosure: return "abnormalClosure"
        case .invalidFramePayloadData: return "invalidFramePayloadData"
        case .policyViolation: return "policyViolation"
        case .messageTooBig: return "messageTooBig"
        case .mandatoryExtensionMissing: return "mandatoryExtensionMissing"
        case .internalServerError: return "internalServerError"
        case .tlsHandshakeFailure: return "tlsHandshakeFailure"
        @unknown default: return "Unknown close code"
        }
    }
}
