//
//  WebRTCMessage.swift
//  Audio
//
//  Created by Aaron Zheng on 1/17/24.
//

import Foundation
import WebRTC

// Mainly for encoding and decoding messages
enum WebRTCMessage {
    case roomCharacteristic(RoomCharacteristics)
    
    case justConnectedUser(JustConnectedUser)
    case justDisconnectedUser(DisconnectedUser)
    case startGame
    case startGameResult(StartGameResult)
    case endGame
    case sdp(SessionDescription)
    case candidate(IceCandidate)
}

extension WebRTCMessage: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
            
        case String(describing: RoomCharacteristics.self):
            self = .roomCharacteristic(try container.decode(RoomCharacteristics.self, forKey: .payload))
        case String(describing: SessionDescription.self):
            self = .sdp(try container.decode(SessionDescription.self, forKey: .payload))
        case String(describing: IceCandidate.self):
            self = .candidate(try container.decode(IceCandidate.self, forKey: .payload))
        case String(describing: JustConnectedUser.self):
            self = .justConnectedUser(try container.decode(JustConnectedUser.self, forKey: .payload))
        case String(describing: DisconnectedUser.self):
            self = .justDisconnectedUser(try container.decode(DisconnectedUser.self, forKey: .payload))
        case "StartGame":
            self = .startGame
        case "EndGame":
            self = .endGame
        case String(describing: StartGameResult.self):
            self = .startGameResult(try container.decode(StartGameResult.self, forKey: .payload))
        default:
            print("DEBUG: Got type a message from the server of type:", type)
            throw DecodeError.unknownType
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sdp(let sessionDescription):
            try container.encode(sessionDescription, forKey: .payload)
            try container.encode(String(describing: SessionDescription.self), forKey: .type)
        case .candidate(let iceCandidate):
            try container.encode(iceCandidate, forKey: .payload)
            try container.encode(String(describing: IceCandidate.self), forKey: .type)
        case .justConnectedUser(let userUUID):
            try container.encode(userUUID, forKey: .payload)
            try container.encode(String(describing: JustConnectedUser.self), forKey: .type)
        case .justDisconnectedUser(let disconnectedUser):
            try container.encode(disconnectedUser, forKey: .payload)
            try container.encode(String(describing: DisconnectedUser.self), forKey: .type)
        case .startGame:
            try container.encode("StartGame", forKey: .type)
        case .endGame:
            try container.encode("EndGame", forKey: .type)
        // Only for testing purposes, can be deleted in production
        case .roomCharacteristic(_):
            print("DEBUG: Encoding room characteristic")
        case .startGameResult(_):
            print("DEBUG: Encoding start game error characteristic")
        }
    }
    
    enum DecodeError: Error {
        case unknownType
    }
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
}

struct RoomCharacteristics: Codable {
    var roomID: String?
    var hostUUID: String?
    var gameState: GameState?
}

enum GameState: String, Codable {
    case InGame
    case InLobby
}

struct StartGameResult: Codable {
    let result: String
}

struct JustConnectedUser: Codable {
    let userUUID: String
}

struct DisconnectedUser: Codable {
    let userUUID: String
    let newHost: String?
}

struct IceCandidate: Codable {
    let fromUUID: String
    let toUUID: String
    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
    
    init(fromUUID: String, toUUID: String, from iceCandidate: RTCIceCandidate) {
        self.sdpMLineIndex = iceCandidate.sdpMLineIndex
        self.sdpMid = iceCandidate.sdpMid
        self.sdp = iceCandidate.sdp
        self.fromUUID = fromUUID
        self.toUUID = toUUID
    }
    
    var rtcIceCandidate: RTCIceCandidate {
        return RTCIceCandidate(sdp: self.sdp, sdpMLineIndex: self.sdpMLineIndex, sdpMid: self.sdpMid)
    }
}

/// This struct is a swift wrapper over `RTCSessionDescription` for easy encode and decode
struct SessionDescription: Codable {
    let fromUUID: String
    let toUUID: String
    let sdp: String
    let type: SdpType
    
    init(fromUUID: String, toUUID: String, data rtcSessionDescription: RTCSessionDescription) {
        self.sdp = rtcSessionDescription.sdp
        
        switch rtcSessionDescription.type {
        case .offer:    self.type = .offer
        case .prAnswer: self.type = .prAnswer
        case .answer:   self.type = .answer
        case .rollback: self.type = .rollback
        @unknown default:
            fatalError("Unknown RTCSessionDescription type: \(rtcSessionDescription.type.rawValue)")
        }
        
        self.fromUUID = fromUUID
        self.toUUID = toUUID
    }
    
    var rtcSessionDescription: RTCSessionDescription {
        return RTCSessionDescription(type: self.type.rtcSdpType, sdp: self.sdp)
    }
}

/// This enum is a swift wrapper over `RTCSdpType` for easy encode and decode
enum SdpType: String, Codable {
    case offer, prAnswer, answer, rollback
    
    var rtcSdpType: RTCSdpType {
        switch self {
        case .offer:    return .offer
        case .answer:   return .answer
        case .prAnswer: return .prAnswer
        case .rollback: return .rollback
        }
    }
}
