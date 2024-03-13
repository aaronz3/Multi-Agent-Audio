//
//  GlobalPlayersViewModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/11/24.
//

import Foundation

class GlobalPlayersViewModel: ObservableObject {
    
    @Published var userStatus: [UserStatus] = []
    
    let url: URL
    var statusCheckTask: Task<Void, Never>? = nil

    init(url: URL) {
        self.url = url
    }
    
    @MainActor
    func getUserStatus() async throws {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("DEBUG: HTTP Request failed", response)
            throw URLError(.unknown)
        }

        self.userStatus = try JSONDecoder().decode([UserStatus].self, from: data)

        print("Updated user status \(self.userStatus)")        
    } 
}


