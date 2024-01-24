//
//  MenuBar.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import SwiftUI

struct MenuBarView: View {
    
    @EnvironmentObject var webRTCModel: WebRTCModel
    
//    var webRTCModel: WebRTCModel
//    var currentUserModel: CurrentUserModel

    @State private var isLongPressed = false
    
    var body: some View {
        HStack {
            
            connect
            
            talk
            
            getInfo

        }
    }
    
    var connect: some View {
        Button("Connect") {
            do {
                try self.webRTCModel.signalingClient.connect()
            } catch {
                print("DEBUG: \(error.localizedDescription)")
            }
        }
        .disabled(webRTCModel.signalingConnected)
    }
    
    var talk: some View {
        Button("Talk") { }
            .padding(20.0)
            .onLongPressGesture(
                perform: {},
                onPressingChanged: { pressed in
                    if pressed {
                        
                        self.webRTCModel.unmuteAudio()
                        isLongPressed.toggle()
                    } else {
                        self.webRTCModel.muteAudio()
                        isLongPressed.toggle()
                    }
                }
            )
            .disabled(webRTCModel.disableTalkButton)
    }
    
    var getInfo: some View {
        Button("Get Info") {
            print("Initial Peer Connection Object UUID:", webRTCModel.peerConnections.first?.receivingAgentsUUID ?? "nil")
            print("Number of peer connections:", webRTCModel.peerConnections.count)
        }
    }
}

//#Preview {
//    MenuBarView()
//}
