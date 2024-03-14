//
//  GlobalPlayersView.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/11/24.
//

import SwiftUI

struct GlobalPlayersView: View {
    
    @EnvironmentObject var globalPlayersVM: GlobalPlayersViewModel
    
    var body: some View {
        VStack {
            HStack {
                Button("", systemImage: "chevron.backward") {
                    globalPlayersVM.userStatus = []
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            List(globalPlayersVM.userStatus) { user in
                HStack {
                    Spacer() // Spacer before the text to push it to the middle
                    VStack {
                        Text(user.userId)
                        Text(user.playerStatus)
                    }
                    Spacer() // Spacer after the text to keep it centered
                }
            }
            .padding(20)
        }
        .padding(20)
        .refreshable {
            Task {
                try await globalPlayersVM.getUserStatus()
            }
        }
    }
}

#Preview {
    GlobalPlayersView()
}
