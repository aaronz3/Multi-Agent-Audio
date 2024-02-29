//
//  WebRTCView.swift
//  Audio
//
//  Created by Aaron Zheng on 1/8/24.
//

import SwiftUI
import GameKit

struct WebRTCView: View {
    
    @EnvironmentObject var authenticationVM: AuthenticationViewModel
    
    @EnvironmentObject var webRTCVM: WebRTCViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        
        VStack {
            Spacer()
            Text("Current user name is: " + (authenticationVM.userData?.userName)!)
                .padding(20)
            
            Text("Current user UUID is: " + (GKLocalPlayer.local.playerID))
                .padding(20)
            
            Text("Connected via websockets:" + (webRTCVM.signalingConnected ? "✅" : "❌"))
                .padding(20)
            
            if webRTCVM.signalingConnected {
                List {
                    ForEach(webRTCVM.peerConnections) {pC in
                        Text("PC Receiving Agent's UUID:" + (pC.receivingAgentsUUID ?? "nil"))
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

