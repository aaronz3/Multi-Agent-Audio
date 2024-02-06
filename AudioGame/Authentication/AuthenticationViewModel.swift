//
//  AuthenticationViewModel.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/5/24.
//

import Foundation
import GameKit

class AuthenticationViewModel: ObservableObject {
    
    @Published var userID: String?
    let localPlayer = GKLocalPlayer.local
 
    func authenticateViaGameCenter() {
        localPlayer.authenticateHandler = { viewController, error in
            if let viewController = viewController,
               let rootController = UIApplication.shared.windows.first?.rootViewController {
                // If there's a viewController, present it to complete authentication
                rootController.present(viewController, animated: true) {
                    self.setUserIDViaGameCenter(localPlayer: self.localPlayer)
                }
            } else if self.localPlayer.isAuthenticated {
                self.setUserIDViaGameCenter(localPlayer: self.localPlayer)
            } else if let error {
                // Handle authentication error
                print("DEBUG: Error in authenticateViaGameCenter. \(error.localizedDescription)")
            }
        }
    }
    
    func setUserIDViaGameCenter(localPlayer: GKLocalPlayer) {
        print("NOTE: Playerid using game center login is \(localPlayer.playerID)")
        self.userID = localPlayer.playerID
        
        // TODO: Send the uuid to the server
        
        
    }
  
}

