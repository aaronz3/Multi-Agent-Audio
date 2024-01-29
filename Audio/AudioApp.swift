//
//  AudioApp.swift
//  Audio
//
//  Created by Aaron Zheng on 11/20/23.
//

import SwiftUI

@main
struct AudioApp: App {
    
    @StateObject var webRTCVM = WebRTCViewModel(signalingClient: SignalingClient(url: defaultSignalingServerUrl, currentUserUUID: CurrentUserModel.loadUsername()))
    @StateObject var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            WebRTCView()
                .environmentObject(webRTCVM)
                .environmentObject(networkMonitor)
            
        }
    }
}

// This is set to amazon ec2 signaling server.
//let defaultSignalingServerUrl = URL(string: "wss://impactsservers.com:3000/play")!
let defaultSignalingServerUrl = URL(string: "ws://172.20.10.7:3000/play")!

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
let defaultIceServers = ["stun:stun.l.google.com:19302",
                         "stun:stun1.l.google.com:19302",
                         "stun:stun2.l.google.com:19302",
                         "stun:stun3.l.google.com:19302",
                         "stun:stun4.l.google.com:19302"]
