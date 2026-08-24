//
//  AudioService.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import AVFoundation

/// Service that manages audio session configuration and microphone permissions
class AudioService {
    /// Shared singleton instance
    static let shared = AudioService()

    private init() {}

    /// Arms the session for speech recognition. Call only when recording starts.
    func activateForRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetoothHFP]
        )
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }

    /// Releases the session after recognition ends so other audio can resume.
    func deactivateAfterRecording() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            AppLog.debug("[AudioService] Deactivate failed: \(error)")
        }
    }

    /// Requests microphone permission from the user
    /// - Parameter completion: Callback with true if permission granted, false otherwise
    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }
}
