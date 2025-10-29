//
//  AudioService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import AVFoundation

class AudioService {
    static let shared = AudioService()
    
    private init() {}
    
    func setupAudioSession() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
}

