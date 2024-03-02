//
//  MonitorAudioTest.swift
//  AudioGameTests
//
//  Created by Aaron Zheng on 3/2/24.
//

import XCTest
@testable import AudioGame

final class MonitorAudioTest: XCTestCase {

    var monitorAudio: MonitorAudio! = nil
    
    override func setUp() {
        monitorAudio = MonitorAudio()
    }
    
    override func tearDown() {
        monitorAudio = nil
    }
    
//    func testStartMonitoringAudioLevel() async throws {
//        try monitorAudio.setupAudioRecorder()
//        try await monitorAudio.startMonitoringAudioLevel()
//        await monitorAudio.asyncDelay(seconds: 1)
//        try monitorAudio.stopMonitoringAudioLevel()
//        
//        
//        
//    }
}
