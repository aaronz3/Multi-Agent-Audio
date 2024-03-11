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
    @StateObject var networkMonitor = NetworkMonitor()

    var body: some Scene {
        WindowGroup {
            AuthenticationView()
                .environmentObject(authenticationVM)
                .environmentObject(networkMonitor)
            
        }
    }
}

// apartment: 192.168.1.2
// house: 192.168.0.6
// 自习室: 192.168.0.211
// ec2: 43.203.40.34

let hostAddress = "43.203.40.34"
let port = "3000"

let loginUrl = URL(string: "http://\(hostAddress):\(port)/login")!
let userStatusUrl = URL(string: "http://\(hostAddress):\(port)/status")!
let defaultSignalingServerUrl = URL(string: "ws://\(hostAddress):\(port)/play")!

//let defaultSignalingServerUrl = URL(string: "ws://172.20.10.7:3000/play")!

let defaultIceServers = ["stun:stun.l.google.com:19302",
                         "stun:stun1.l.google.com:19302",
                         "stun:stun2.l.google.com:19302",
                         "stun:stun3.l.google.com:19302",
                         "stun:stun4.l.google.com:19302"]
