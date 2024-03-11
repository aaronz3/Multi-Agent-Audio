//
//  MenuBar.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import SwiftUI
import GameKit

struct MenuBarView: View {
    
    @EnvironmentObject var playVM: PlayViewModel
    @EnvironmentObject var authenticationVM: AuthenticationViewModel

    @State private var isLongPressed = false
    @State private var showStartGameResult = false
    
    var body: some View {
        HStack {
            // Only show the play button and the result if the client is the host
            if let hostUUID = playVM.roomCharacteristics.hostUUID,
                hostUUID == playVM.signalingClient.currentUserUUID {
                VStack {
                    gameState()
                    
                    if let result = playVM.startGameResult {
                        startGameResult(result: result)
                    }

                }
                
            }

            talk()
            
        }
    }
    
    func gameState() -> some View {
        let inLobby = playVM.roomCharacteristics.gameState == .InLobby
        return Button(inLobby ? "Start Game" : "End Game") {
            Task {
                do {
                    try await playVM.signalingClient.send(message: inLobby ? .startGame : .endGame)
                    
                } catch {
                    print("DEBUG: Failed to send start game")
                }
            }
        }
        
    }
    
    func startGameResult(result: String) -> some View {

        Text(result)
            .onAppear {
                showStartGameResult.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showStartGameResult.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.4) {
                    playVM.startGameResult = nil
                }
            }
            .opacity(showStartGameResult ? 1 : 0)
            .offset(y: showStartGameResult ? 0 : -20)
            .animation(.spring(duration:0.4, bounce:0.4), value: showStartGameResult)
        
    }
    
    func talk() -> some View {
        Button("Talk") { }
            .padding(20.0)
            .onLongPressGesture(
                perform: {},
                onPressingChanged: { pressed in
                    handlePressedTalk(pressed: pressed)
                }
            )
            .disabled(playVM.disableTalkButton)
    }

    func handlePressedTalk(pressed: Bool) {
        if pressed {
            self.playVM.unmuteAudio()
            isLongPressed.toggle()
        } else {
            self.playVM.muteAudio()
            isLongPressed.toggle()
        }
    }
}

//#Preview {
//    MenuBarView()
//}
