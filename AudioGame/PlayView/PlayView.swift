//
//  PlayView.swift
//  Audio
//
//  Created by Aaron Zheng on 1/8/24.
//

import SwiftUI
import GameKit

struct PlayView: View {
    
    @EnvironmentObject var authenticationVM: AuthenticationViewModel
    @EnvironmentObject var playVM: PlayViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
        
    var body: some View {
        
        VStack {
            Spacer()
            handleHeaderView()
            
            Text("Current user name: " + (authenticationVM.userData?.userName)!)
                .padding(20)
            
            Text("Current user UUID: " + (GKLocalPlayer.local.playerID))
                .padding(20)
            
            Text("Current game state: " + ((playVM.roomCharacteristics?.gameState.rawValue) ?? "unknown"))
            
            handleListingAgentsView()
            
            MenuBarView()
            Spacer()
        }
        .padding(20)
        .onAppear {
            networkMonitor.start()
            HandleAudioSession.speakerOn()
        }
        
    }
    
    func handleListingAgentsView() -> some View {
        List {
            ForEach(playVM.peerConnections) {pC in
                HStack {
                    if let hostUUID = playVM.roomCharacteristics?.hostUUID,
                       let agentUUID = pC.receivingAgentsUUID,
                        agentUUID == hostUUID {
                        Image(systemName: "star.fill")
                            .renderingMode(.original)
                    }
                    
                    Text("PC Receiving Agent's UUID:" + (pC.receivingAgentsUUID ?? "nil"))
                    
                    Spacer()
                    
                    VStack {
                        
                        Rectangle()
                            .fill(Color.green) // Set the background color of the rectangle to green.
                            .frame(width: 20, height: 40 * CGFloat(pC.receivingAudioLevel), alignment: .bottom)
                        
                    }
                    
                    Spacer()
                        
                }
            }
        }
        .padding(20)
    }
    
    func handleHeaderView() -> some View {
        HStack {
            
            Button("", systemImage: "chevron.backward") {
                Task {
                    do {
                        let leaveMessage = DisconnectedUser(userUUID: playVM.signalingClient.currentUserUUID)
                        try await playVM.signalingClient.send(message: .justDisconnectedUser(leaveMessage))
                        playVM.signalingClient.disconnect()
                        playVM.webSocketDidDisconnect()
                    } catch {
                        print("DEBUG: Unable to send end gamemessage")
                    }
                }
            }
            
            Spacer()
            
            Text("Room: " + (playVM.roomCharacteristics?.roomID ?? "Unavaliable"))
                .padding(20)
                .frame(alignment: .center)
            
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

