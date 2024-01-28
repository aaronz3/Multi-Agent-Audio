//
//  WebRTCView.swift
//  Audio
//
//  Created by Aaron Zheng on 1/8/24.
//

import SwiftUI

struct WebRTCView: View {
    
    @EnvironmentObject var webRTCVM: WebRTCViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor

//    var webRTCVM: webRTCVM
//    var currentUserModel: CurrentUserModel

    var body: some View {
        
        VStack {
            
            Text("Current user UUID is:" + (CurrentUserModel.loadUsername()))
                .padding(20)
            
            Text("Signaling Status:" + (webRTCVM.signalingConnected ? "✅" : "❌"))
                .padding(20)
            
            List {
                ForEach(webRTCVM.peerConnections) {pC in
                    Text("PC Receiving Agent's UUID:" + (pC.receivingAgentsUUID ?? "nil"))
                }
            }
            .padding(20)
            
            .padding(20)
            
            MenuBarView()
        }
        .onAppear {
            networkMonitor.start()
            HandleAudioSession.checkAudioPermission()
            HandleAudioSession.speakerOn()
        }
        
    }
    
    
}


//#Preview {
//    WebRTCView(webRTCVM: , currentUserModel: currentUserModel)
//}
