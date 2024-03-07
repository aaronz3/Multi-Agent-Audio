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
    @EnvironmentObject var networkMonitor: NetworkMonitor

    @State var serverDown = false
    @State var noInternet = false
    
    var body: some View {
        ZStack {
            // Perhaps put a background here.
//            Image("Background")
//                .resizable()
//                .scaledToFill()
//                .ignoresSafeArea()
            
            // In order for the main menu to appear, these conditions must be fulfilled.
            //   (1) the playerID exists from the authentication
            //   (2) the user data has been imported
            //   (3) there is a viable internet connection
            // If any of the above conditions is not true show the user which condition is not fulfilled.
            
            if GKLocalPlayer.local.playerID != ""
                && authenticationVM.userData != nil
                && networkMonitor.previousNetwork != nil {
                
                // Display the main menu
                MainMenuView()
                    .onAppear(perform: HandleAudioSession.checkAudioPermission)
                    
            } else if serverDown {
                Text("Server Down")
                    .font(.title)
                    .scaleEffect(1)
            
            } else if noInternet || networkMonitor.previousNetwork == nil {
                handleNoInternetView()
                
            } else {
                ProgressView().scaleEffect(1.5, anchor: .center)
            }
        }
        .onAppear {
            networkMonitor.start()
            handleOnAppear()
        }
    }
    
    func handleNoInternetView() -> some View {
        VStack {
            Text("Network Down. Please turn on wifi or cellular data to use this app.")
                .font(.title)
                .scaleEffect(1)
                .padding(50)
            
            Button("Retry") {
                handleOnAppear()
            }
        }
    }
    
    func handleOnAppear() {
        Task {
            do {
                // Check to see if userID is nil
                if GKLocalPlayer.local.playerID == "" {
                    try await authenticationVM.authenticateViaGameCenter()
                }
                try await authenticationVM.getUserData()
                
                serverDown = false
                noInternet = false
                
            } catch AuthenticationError.serverError {
                serverDown = true
            } catch let error as URLError {
                // Show a view with the option to retry authentication or quit the app
                // If the retried authentication fails, redisplay the view
                noInternet = true
            } catch {
                // Handle all other errors
                print("DEBUG:", error.localizedDescription)
                fatalError()
            }
        }
    }
}



#Preview {
    AuthenticationView()
}
