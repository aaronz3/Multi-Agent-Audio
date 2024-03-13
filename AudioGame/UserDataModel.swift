//
//  UserDataModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/17/24.
//

import Foundation

struct UserStatus: Codable, Identifiable {
    var id: String { userId }
    var userId: String
    var playerStatus: String
    
    enum CodingKeys: String, CodingKey {
        case playerStatus = "Player-Status"
        case userId = "User-ID"
    }
    
    struct AttributeValue: Codable {
        let S: String?
    }
    
    init(userId: String, playerStatus: String) {
        self.playerStatus = playerStatus
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusAttribute = try container.decode(AttributeValue.self, forKey: .playerStatus)
        let userIdAttribute = try container.decode(AttributeValue.self, forKey: .userId)

        guard let playerStatus = statusAttribute.S,
              let userId = userIdAttribute.S
        else {
            throw DecodingError.dataCorruptedError(forKey: .playerStatus, in: container, debugDescription: "Expected String value")
        }
        
        self.playerStatus = playerStatus
        self.userId = userId
        
    }
}

struct UserRecord: Codable {
    var userName: String
    var userId: String
    let previousRoom: String? = nil
    
    enum CodingKeys: String, CodingKey {
        case userName = "User-Name"
        case userId = "User-ID"
        case previousRoom = "Previous-Room"
    }
    
    struct AttributeValue: Codable {
        let S: String?
    }
    
    init(userId: String, userName: String) {
        self.userName = userName
        self.userId = userId
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let userNameAttribute = try container.decode(AttributeValue.self, forKey: .userName)
        let userIdAttribute = try container.decode(AttributeValue.self, forKey: .userId)
        
        guard let userName = userNameAttribute.S,
              let userId = userIdAttribute.S
        else {
            throw DecodingError.dataCorruptedError(forKey: .userName, in: container, debugDescription: "Expected String value")
        }
        
        self.userName = userName
        self.userId = userId
    }
}

