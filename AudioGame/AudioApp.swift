//
//  AudioApp.swift
//  Audio
//
//  Created by Aaron Zheng on 11/20/23.
//

import SwiftUI

@main
struct AudioApp: App {
    
    @StateObject var authenticationVM = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authenticationVM)
            
        }
    }
}

// apartment: 192.168.1.3
// house: 192.168.0.6
// ec2: 43.203.40.34

let hostAddress = "43.203.40.34"
let port = "3000"

let userIDUrl = URL(string: "http://\(hostAddress):\(port)/user-data")!

// This is set to amazon ec2 signaling server.
let defaultSignalingServerUrl = URL(string: "ws://\(hostAddress):\(port)/play")!
//let defaultSignalingServerUrl = URL(string: "ws://172.20.10.7:3000/play")!

// We use Google's public stun servers. For production apps you should deploy your own stun/turn servers.
let defaultIceServers = ["stun:stun.l.google.com:19302",
                         "stun:stun1.l.google.com:19302",
                         "stun:stun2.l.google.com:19302",
                         "stun:stun3.l.google.com:19302",
                         "stun:stun4.l.google.com:19302"]
