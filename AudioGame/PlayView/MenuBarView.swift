//
//  MenuBar.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import SwiftUI
import GameKit

struct MenuBarView: View {
    
    @EnvironmentObject var playVM: PlayViewModel
    @EnvironmentObject var authenticationVM: AuthenticationViewModel

    @State private var isLongPressed = false

    var body: some View {
        HStack {
            talk()
        }
    }
    
    func talk() -> some View {
        Button("Talk") { }
            .padding(20.0)
            .onLongPressGesture(
                perform: {},
                onPressingChanged: { pressed in
                    handlePressedTalk(pressed: pressed)
                }
            )
            .disabled(playVM.disableTalkButton)
    }

    func handlePressedTalk(pressed: Bool) {
        do {
            if pressed {
                self.playVM.unmuteAudio()
                isLongPressed.toggle()
            } else {
                self.playVM.muteAudio()
                isLongPressed.toggle()
            }
        } catch {
            print("DEBUG: Error in handlePressedTalk \(error.localizedDescription)")
        }
    }
}

//#Preview {
//    MenuBarView()
//}
