//
//  MainMenu.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/1/24.
//

import SwiftUI
import GameKit

struct MainMenuView: View {
    
    @EnvironmentObject var authenticationVM: AuthenticationViewModel

    @StateObject var playVM = PlayViewModel(signalingClient:
                                                SignalingClient(url: defaultSignalingServerUrl, currentUserUUID: GKLocalPlayer.local.playerID))
    
    @State var isProcessingPlayTask = false
    @State var loadingError = false
    
    var body: some View {
        
        // If signaling client connected then show the play view
        if playVM.signalingConnected {
        
            // Display the play view
            PlayView()
                .environmentObject(playVM)
        
        // If still processing the play task load the progress view
        } else if isProcessingPlayTask {

            ProgressView()
        
        // If something went wrong when trying to play
        } else if loadingError {
            Text("Something went wrong").onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    loadingError = false
                }
            }
        
        // Give the user the option to connect to server
        } else {
            handleMainMenuView()
        }
    }
    
    func handleMainMenuView() -> some View {
        VStack {
            Text("Current user name: " + (authenticationVM.userData?.userName)!)
                .padding(20)
            
            Text("Current user UUID: " + (GKLocalPlayer.local.playerID))
                .padding(20)
            
            Button("PLAY") {
                Task {
                    isProcessingPlayTask = true
                    
                    do {
                        try await self.playVM.signalingClient.connect()
                    } catch {
                        loadingError = true
                    }
                    
                    isProcessingPlayTask = false
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
}
