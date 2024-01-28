//
//  MockSignalingClient.swift
//  AudioTests
//
//  Created by Aaron Zheng on 1/28/24.
//

import Foundation

protocol Signaling {
    var currentUserUUID: String? { get set }
    func connect() async throws
    func disconnect()
}

class MockSignalingClient: Signaling {
    
    var currentUserUUID: String?
    
    
    func connect() async throws {
        
    }
    
    func disconnect() {
        
    }
}
