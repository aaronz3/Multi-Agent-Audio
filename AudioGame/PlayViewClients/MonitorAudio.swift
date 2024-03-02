//
//  MonitorAudio.swift
//  AudioGame
//
//  Created by Aaron Zheng on 3/2/24.
//

import Foundation
import AVFoundation

class MonitorAudio {
    
    var audioRecorder: AVAudioRecorder?
    var audioLevel: Float?
    
    func setupAudioRecorder() throws {
        let audioFilename = FileManager.default.temporaryDirectory.appendingPathComponent("tempAudio.m4a")

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }
    
    func startMonitoringAudioLevel(callback: @escaping (Float) -> ()) throws {
        
        guard audioRecorder != nil else { throw NSError() }
                
        audioRecorder!.record()
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.audioRecorder!.isRecording {
                audioRecorder!.updateMeters()
                let averagePower = audioRecorder!.averagePower(forChannel: 0)
                let normalizedPower = (averagePower + 160.0) / 160.0
                callback(normalizedPower)
            }
        }
        
    }
    
    func stopMonitoringAudioLevel() throws {
        guard audioRecorder != nil else { throw NSError() }

        audioRecorder!.stop()
    }

}
