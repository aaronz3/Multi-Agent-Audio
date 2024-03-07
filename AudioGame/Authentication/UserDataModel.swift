//
//  UserDataModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/17/24.
//

import Foundation

// Uploading user data
struct User: Codable {
    var id: String
    var name: String
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
    
    init(userName: String, userId: String) {
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
