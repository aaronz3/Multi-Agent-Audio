//
//  CurrentUserModel.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import Foundation

enum UserPersonalData {
    
}

class CurrentUserModel: ObservableObject {
    
    var request: URLRequest

    init(url: URL) {
        self.request = URLRequest(url: url)
    }
    
    func uploadUserData(_ data: String) async {

        let testData = WebRTCMessage.justConnectedUser(JustConnectedUser(userUUID: data))
        
        guard let uploadData = try? JSONEncoder().encode(testData) else {
            return
        }
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = uploadData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(data, response)
            
        } catch {
            print("DEBUG: \(error.localizedDescription)")
        }
        
    }
    
}
