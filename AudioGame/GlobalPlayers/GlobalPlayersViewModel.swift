//
//  GlobalPlayersViewModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/11/24.
//

import Foundation

class GlobalPlayersViewModel: ObservableObject {
    
    let url: URL
    var userStatus: [UserStatus] = []
    
    init(url: URL) {
        self.url = url
    }
    
    func getUserStatus() async throws {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.unknown)
        }
        print(String(data: data, encoding: .utf8))
    }
    
    
}


