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
    func webSocket(didReceiveData data: Data)
}

enum SendMessageType {
    case sdp(RTCSessionDescription)
    case candidate(RTCIceCandidate)
    case justConnectedUser(String)
    case disconnectedUser(String)
}

enum SignalingErrors: Error {
    case noUserID
}

class SignalingClient: NSObject, ObservableObject {
    
    let url: URL
    var urlSession: URLSession?
    var webSocket: URLSessionWebSocketTask?
    weak var weakWebSocket: URLSessionWebSocketTask?

//    var pingTimer: Timer?
    var delegate: WebSocketProviderDelegate?

    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    
    let currentUserUUID: String?

    // TODO: Only for testing purposes
    var processDataCompletion: ((String) -> ())?
    
    init(url: URL) {
        
        self.url = url
        self.currentUserUUID = CurrentUserModel.loadUsername()
        
        super.init()
        
    }

    deinit {
        print("NOTE: Signaling Client deinitialized")
    }
    
    func connect() throws {
        if self.webSocket != nil {
            print("Note: A previous websocket task existed.")
            self.disconnect()
        }
        
        self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        self.webSocket = self.urlSession!.webSocketTask(with: url)
        self.webSocket!.resume()
        
        // Start receiving messages from the server
        self.readMessage()
        
        // Send over the current agent's UUID to other agents
        guard let uuid = self.currentUserUUID else {
            throw SignalingErrors.noUserID
        }
        
        self.send(toUUID: nil, message: .justConnectedUser(uuid))
        
        // Send a ping to server every once in a while
//        self.schedulePingTimer()
        
        // Alert the data model that a websocket connection has been established
        self.delegate?.webSocketDidConnect()
    }
    
//    func schedulePingTimer() {
//        // Schedule a timer to send a ping every 10 seconds (adjust as needed)
//        pingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak webSocket = self.webSocket] timer in
//            
//            guard let webSocket else {
//                print("NOTE: Websocket does not exist. Exit ping")
//                timer.invalidate()
//                return
//            }
//            
//            // Send a ping frame
//            webSocket.sendPing { [weak webSocket = self.webSocket] error in
//                if let error {
//                    // Handle the error (e.g., connection issue)
//                    print("NOTE: Failed to send ping: \(error.localizedDescription)")
//                    timer.invalidate()
//                    
//                }
//            }
//        }
//    }
 
    func readMessage() {
        self.webSocket?.receive { message in
 
            switch message {
            case .success(let type):
                switch type {
                case .data(let data):
                    
                    self.delegate?.webSocket(didReceiveData: data)
                    self.readMessage()
                    
                case .string(let string):
                    print("DEBUG: Got string", string)
                }
                
            case .failure(let error):
                
                print("DEBUG: Failed to receive data, disconnecting websockets.", error.localizedDescription)
                
                // TODO: Only for testing purposes
                self.processDataCompletion?("FailedInReceiving")
                
                return
            
            }
        }
    }
    
    func send(toUUID: String?, message: SendMessageType) {
        
        guard let userUUID = self.currentUserUUID else {
            print("DEBUG: No current user id")
            return
        }
        
        var sendMessageContext: Message
        var printMessageType: String
        
        switch message {
        case .sdp(let sdp):
            guard let toUUID else {
                print("DEBUG: No final destination user id")
                return
            }
            
            sendMessageContext = Message.sdp(SessionDescription(fromUUID: userUUID, toUUID: toUUID, data: sdp))
            printMessageType = "SDP"
            
        case .candidate(let iceCandidate):
            guard let toUUID else {
                print("DEBUG: No final destination user id")
                return
            }
            
            sendMessageContext = Message.candidate(IceCandidate(fromUUID: userUUID, toUUID: toUUID, from: iceCandidate))
            printMessageType = "candidate"
            
        case .justConnectedUser(let uuid):
            
            sendMessageContext = Message.justConnectedUser(JustConnectedUser(userUUID: uuid))
            printMessageType = "current connected agent's UUID"
        
        case .disconnectedUser(let uuid) :
            
            sendMessageContext = Message.justDisconnectedUser(DisconnectedUser(userUUID: uuid))
            printMessageType = "current disconnected agent's UUID"
        }
        
        encodeToSend(sendMessageContext: sendMessageContext, printMessageType: printMessageType)
    }
    
    
    func encodeToSend(sendMessageContext: Message, printMessageType: String) {
        do {
            let dataMessage = try self.encoder.encode(sendMessageContext)
            
//          This is to get sample sdp and candidate for testing purposes
//            guard let jsonString = String(data: dataMessage, encoding: .utf8) else {
//                print("Error converting data to string")
//                return
//            }
//            print(jsonString)
            
            if self.webSocket == nil {
                print("NOTE: Websocket object in signaling class is nil.")
            }
            
            self.webSocket?.send(.data(dataMessage)) { error in
                
                guard error == nil else {
                    print("DEBUG: Unable to send \(printMessageType).", error!.localizedDescription)
                    return
                }
                
                print("SUCCESS: Successfully sent \(printMessageType)")
                
                // TODO: Only for testing purposes
                self.processDataCompletion?("SentUUID")
            }
            
        }
        catch {
            print("DEBUG: Could not encode \(printMessageType).", error.localizedDescription)
        }
    }
   
    func disconnect() {
        
        self.webSocket?.cancel(with: .normalClosure, reason: nil)
        self.webSocket = nil
              
        self.delegate?.webSocketDidDisconnect()
        
        // TODO: Only for testing purposes
        self.processDataCompletion?("Disconnected")
    }
        
}

extension SignalingClient: URLSessionWebSocketDelegate, URLSessionDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {

    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("NOTE: Websocket closed by websocket delegate. Reason:", closeCode.description)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        if let error = error as NSError? {
            
            // Check if user has internet.
            if error.domain == NSURLErrorDomain && error.code == NSURLErrorNetworkConnectionLost {
                print("NOTE: Network connection lost")
                
                self.disconnect()
                
            }

            // Handle the "Socket is not connected" error
            if error.domain == NSPOSIXErrorDomain && error.code == 57 {
                print("NOTE: Socket is not connected")
                
                self.disconnect()
            }
            
        }
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

class WebSocketTask: URLSessionWebSocketTask {
    deinit {
        print("")
    }
}

