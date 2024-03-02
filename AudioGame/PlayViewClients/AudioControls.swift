//
//  CheckAudioPermission.swift
//  Audio
//
//  Created by Aaron Zheng on 1/15/24.
//

import Foundation
import AVFoundation
import WebRTC

// TODO: Test this code
class HandleAudioSession {
    
    static private let rtcAudioSession = RTCAudioSession.sharedInstance()
        
    // Set the category and mode for the audio session
    static func configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            
        } catch {
            debugPrint("DEBUG: Error changing AVAudioSession category: \(error.localizedDescription)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    static func speakerOn() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            try self.rtcAudioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try self.rtcAudioSession.overrideOutputAudioPort(.speaker)
            try self.rtcAudioSession.setActive(true)
            
        } catch {
            debugPrint("DEBUG: Couldn't force audio to speaker: \(error.localizedDescription)")
        }
        print("NOTE: Speaker is on")
        self.rtcAudioSession.unlockForConfiguration()
    }
    
    static func checkAudioPermission() {
        // Check the current audio permission status
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // User has granted permission
            if granted {
                print("SUCCESS: Audio permission granted")
                                
            } else {
                // The user denies access. Present a message that indicates
                // that they can change their permission settings in the
                // Privacy & Security section of the Settings app.
                print("DEBUG: The user denies access. Present a message that indicates that they can change their permission settings in the Privacy & Security section of the Settings app.")
            }
        }
    }
}

class MonitorAudio {
    
    private var audioRecorder: AVAudioRecorder?
    
    init() {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("tempAudio.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            print("Failed to initialize AVAudioRecorder. Error: \(error)")
        }
    }
    
    func startMonitoringAudioLevel() {
        audioRecorder?.record()
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.audioRecorder?.updateMeters()
            let averagePower = self?.audioRecorder?.averagePower(forChannel: 0) ?? 0
            print("Current input level: \(averagePower)")
            // You can use this value to update a UI element (e.g., a volume meter).
        }
    }
    
    func stopMonitoringAudioLevel() {
        audioRecorder?.stop()
    }
}
