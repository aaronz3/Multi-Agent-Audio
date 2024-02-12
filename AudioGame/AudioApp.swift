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
            
//            if #available(iOS 16.0, *) {
//                PhotoSelector()
//            } else {
//                // Fallback on earlier versions
//            }
            
            
                
        }
    }
}

let hostAddress = "192.168.1.2"
let port = "3000"

let uploadPhotoUrl = URL(string: "http://\(hostAddress):\(port)/upload-profile-photo")!
let downloadPhotoUrl = URL(string: "http://\(hostAddress):\(port)/download-profile-photo")!

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
