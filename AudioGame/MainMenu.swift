//
//  MainMenu.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/1/24.
//

import SwiftUI
import GameKit

struct MainMenu: View {
    
    @StateObject var playVM = PlayViewModel(signalingClient: SignalingClient(url: defaultSignalingServerUrl))
    
    @State var isProcessingPlayTask = false
    
    var body: some View {
        
        // If signaling client connected then show the play view
        if playVM.signalingConnected {
        
            // Display the play view
            PlayView()
                .environmentObject(playVM)
        
        // If still processing the play task load the progress view
        } else if isProcessingPlayTask {

            ProgressView()
        
        // Give the user the option to connect to server
        } else {
            Button("PLAY") {
                Task {
                    isProcessingPlayTask = true
                    self.playVM.signalingClient.setCurrentUserUUID(uuid: GKLocalPlayer.local.playerID)
                    await self.playVM.signalingClient.connect()
                    
                    isProcessingPlayTask = false
                }
            }
            
        }
    }
}

#Preview {
    MainMenu()
}
