//
//  CheckAudioPermission.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import Foundation
import AVFoundation
import WebRTC

class HandleAudioSession {
    
    static private let rtcAudioSession = RTCAudioSession.sharedInstance()

    // Set the category and mode for the audio session
    static func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            
        } catch let error {
            debugPrint("DEBUG: Error changing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    // MARK: HANDLE SPEAKER
    
    static func speakerOn() {
        
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
            try self.rtcAudioSession.setActive(true)
            
        } catch let error {
            debugPrint("DEBUG: Couldn't force audio to speaker: \(error)")
        }
        print("NOTE: Speaker is on")
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    static func checkAudioPermission() {
        
        // Check the current audio permission status
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                print("NOTE: Audio permission granted")
                // User has granted permission
            } else {
                // The user denies access. Present a message that indicates
                // that they can change their permission settings in the
                // Privacy & Security section of the Settings app.
                print("DEBUG: The user denies access. Present a message that indicates that they can change their permission settings in the Privacy & Security section of the Settings app.")
            }
        }

    }
}
