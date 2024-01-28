//
//  MockURLSessionWebSocketTask.swift
//  Audio
//
//  Created by Aaron Zheng on 1/28/24.
//

import Foundation

protocol NetworkSocket {
    func resume()
    func send(_ message: URLSessionWebSocketTask.Message) async throws
    func receive() async throws -> URLSessionWebSocketTask.Message
    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    )
    
}

extension URLSessionWebSocketTask: NetworkSocket { }

class MockNetworkSocket: NetworkSocket {
    
    var result: ((String) -> ())?
    var message: URLSessionWebSocketTask.Message?
    
    func resume() {
        result?("resume")
    }
    
    func send(_ message: URLSessionWebSocketTask.Message) async throws {
        result?("send")
    }
    
    func receive() async throws -> URLSessionWebSocketTask.Message {
        if message == nil {
            
            await withCheckedContinuation { continuation in
                DispatchQueue.main.asyncAfter(deadline: .now() + 10000) {
                    continuation.resume()
                }
            }

            return .data(Data())
            
        } else {
            return message!
        }
    }
    
    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        result?("cancelled")
    }
}
