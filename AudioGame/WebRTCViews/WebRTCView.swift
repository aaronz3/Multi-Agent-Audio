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
    @EnvironmentObject var currentUserModel: CurrentUserModel
    let testUUID = "test"

    var body: some View {
        
        VStack {
            
            Text("Current user UUID is:" + (currentUserModel.currentUserUUID ?? "nil"))
                .padding(20)
            
            Text("Signaling Status:" + (webRTCVM.signalingConnected ? "✅" : "❌"))
                .padding(20)
            
            List {
                ForEach(webRTCVM.peerConnections) {pC in
                    Text("PC Receiving Agent's UUID:" + (pC.receivingAgentsUUID ?? "nil"))
                }
            }
            .padding(20)
            
            Button("Send data") {
                Task {
                    await currentUserModel.uploadData(data: testUUID)
                }
            }
            
            MenuBarView()
        }
        .onAppear {
//            Task {
//                await currentUserModel.uploadData(data: testUUID)
            // TODO: Only access currentuser by function
//                webRTCVM.signalingClient.currentUserUUID = testUUID
//            }
            
            networkMonitor.start()
            HandleAudioSession.checkAudioPermission()
            HandleAudioSession.speakerOn()
        }
        
    }
    
    
}


//#Preview {
//    WebRTCView(webRTCVM: , currentUserModel: currentUserModel)
//}
