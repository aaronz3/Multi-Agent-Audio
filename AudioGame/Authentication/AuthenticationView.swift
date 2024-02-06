//
//  AuthenticationView.swift
//  AudioGame
//
//  Created by Aaron Zheng on 2/5/24.
//

import SwiftUI
import GameKit

struct AuthenticationView: View {
    
    @EnvironmentObject var authenticationVM: AuthenticationViewModel
    
    @StateObject var webRTCVM = WebRTCViewModel(signalingClient: SignalingClient(url: defaultSignalingServerUrl))
    @StateObject var networkMonitor = NetworkMonitor()
    
    var body: some View {
        ZStack {
            // Perhaps put a background here.
//            Image("Background")
//                .resizable()
//                .scaledToFill()
//                .ignoresSafeArea()
            
            
            if authenticationVM.userID != nil {
                WebRTCView()
                    .environmentObject(webRTCVM)
                    .environmentObject(networkMonitor)
                    
            } else {
                ProgressView().scaleEffect(1.5, anchor: .center)
            }
        }
        .onAppear {
            authenticationVM.authenticateViaGameCenter()
        }
    }
}

#Preview {
    AuthenticationView()
}
