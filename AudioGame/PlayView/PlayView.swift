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
            Text("Room number: " + (playVM.roomCharacteristics?.roomID ?? "Unavaliable"))
                .padding(20)
            
            Text("Current user name: " + (authenticationVM.userData?.userName)!)
                .padding(20)
            
            Text("Current user UUID: " + (GKLocalPlayer.local.playerID))
                .padding(20)

            if playVM.signalingConnected {
                List {
                    ForEach(playVM.peerConnections) {pC in
                        HStack {
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
            
            MenuBarView()
            Spacer()
        }
        .padding(20)
        .onAppear {
            networkMonitor.start()
            HandleAudioSession.checkAudioPermission()
            HandleAudioSession.speakerOn()
        }
        
    }
    
    
}

