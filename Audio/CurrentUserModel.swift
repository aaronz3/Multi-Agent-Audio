//
//  CurrentUserModel.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import Foundation
struct Order: Codable {
    let customerId: String
    let items: [String]
}


class CurrentUserModel: ObservableObject {
    
    var request: URLRequest
    
    @Published var currentUserUUID: String?
    
    init(url: URL) {
        self.request = URLRequest(url: url)
    }
    
    func downloadUUID() async throws {
        
    }
    
    func uploadData(data: String) async {

        let testData = Message.justConnectedUser(JustConnectedUser(userUUID: data))
        
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
    
    func loadUsername() -> String {
        // Load the saved username from UserDefaults
        if let savedUsername = UserDefaults.standard.string(forKey: "username") {
            return savedUsername
        } else {
            let username = UUID().uuidString
            UserDefaults.standard.set(username, forKey: "username")
            return username
        }
    }
}
