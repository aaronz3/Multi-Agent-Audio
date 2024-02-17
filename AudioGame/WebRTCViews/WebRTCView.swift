//
//  WebRTCView.swift
//  Audio
//
//  Created by Aaron Zheng on 1/8/24.
//

import SwiftUI

struct WebRTCView: View {
    
    @EnvironmentObject var authenticationVM: AuthenticationViewModel
    
    @EnvironmentObject var webRTCVM: WebRTCViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        
        VStack {
            Spacer()
            Text("Current user UUID is: " + (authenticationVM.userID!))
                .padding(20)
            
            Text("Signaling Status:" + (webRTCVM.signalingConnected ? "✅" : "❌"))
                .padding(20)
            
            List {
                ForEach(webRTCVM.peerConnections) {pC in
                    Text("PC Receiving Agent's UUID:" + (pC.receivingAgentsUUID ?? "nil"))
                }
            }
            .padding(20)
            
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

