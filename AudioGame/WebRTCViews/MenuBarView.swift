//
//  MenuBar.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import SwiftUI
import GameKit

struct MenuBarView: View {
    
    @EnvironmentObject var webRTCVM: WebRTCViewModel
    @EnvironmentObject var authenticationVM: AuthenticationViewModel

    @State private var isLongPressed = false
    
    var body: some View {
        HStack {
            
            connect()
            
            talk()

        }
    }
    
    func connect() -> some View {
        Button("Connect") {
            Task {
                self.webRTCVM.signalingClient.setCurrentUserUUID(uuid: GKLocalPlayer.local.playerID)
                await self.webRTCVM.signalingClient.connect()
            }
        }
        .disabled(webRTCVM.signalingConnected)
    }
    
    func talk() -> some View {
        Button("Talk") { }
            .padding(20.0)
            .onLongPressGesture(
                perform: {},
                onPressingChanged: { pressed in
                    if pressed {
                        self.webRTCVM.unmuteAudio()
                        isLongPressed.toggle()
                    } else {
                        self.webRTCVM.muteAudio()
                        isLongPressed.toggle()
                    }
                }
            )
            .disabled(webRTCVM.disableTalkButton)
    }
    
    var getInfo: some View {
        Button("Get Info") {
            print("Initial Peer Connection Object UUID:", webRTCVM.peerConnections.first?.receivingAgentsUUID ?? "nil")
            print("Number of peer connections:", webRTCVM.peerConnections.count)
        }
    }
}

//#Preview {
//    MenuBarView()
//}
