//
//  ContentView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/26/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct ContentView: View {
    @StateObject private var speechService = SpeechService()
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var micController: MicController
    @StateObject private var historyManager = HistoryManager.shared
    @State private var editedText = ""
    @State private var previousRecordingState: Bool = false
    @State private var shakeCooldownActive: Bool = false
    
    init() {
        let speechService = SpeechService()
        _speechService = StateObject(wrappedValue: speechService)
        _micController = StateObject(wrappedValue: MicController(speechService: speechService))
    }
    
    var body: some View {
        ZStack {
            // Background color based on mode
            appState.colorMode.background
                .ignoresSafeArea()
            
            // Flash transition
            if appState.showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            // Controls overlay
            ControlsView(
                micController: micController,
                appState: appState,
                onClear: {
                    // Save current text before clearing (poof pressed)
                    saveCurrentTextToHistory()
                    appState.clearScreen()
                    speechService.currentText = ""
                }
            )
            
            // Text display (center)
            VStack {
                Spacer()
                
                if appState.showPoofAnimation {
                    // Show POOF animation
                    Text("✨Poof!!!✨")
                        .font(.system(size: 60, weight: .black, design: .default))
                        .foregroundColor(appState.colorMode.text)
                        .opacity(appState.poofOpacity)
                } else {
                    // Only show text if there's actual content
                    if !speechService.currentText.isEmpty {
                        CaptionTextDisplay(text: speechService.currentText, colorMode: appState.colorMode)
                    } else if micController.isRecording {
                        // Show recording indicator
                        Text("🎤 Listening...")
                            .font(.system(size: 45, weight: .black, design: .default))
                            .foregroundColor(appState.colorMode.text.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
            
            // Keyboard edit overlay - on top of everything
            if appState.showKeyboard {
                KeyboardEditView(
                    appState: appState,
                    text: $editedText,
                    onDone: {
                        // Update text and close keyboard view
                        speechService.currentText = editedText
                        appState.toggleKeyboard()
                    }
                )
                .zIndex(10)
                .onAppear {
                    // Initialize with current text when overlay appears
                    editedText = speechService.currentText
                }
            }
            
            // History overlay - on top of everything
            if appState.showHistory {
                HistoryView(
                    appState: appState,
                    historyManager: historyManager
                )
                .zIndex(10)
            }
        }
        .onChange(of: micController.isRecording) { newValue in
            // When new recording starts, save current text to history
            if !previousRecordingState && newValue {
                // New recording is starting - save previous text
                saveCurrentTextToHistory()
            }
            // Update previous state to track transitions
            previousRecordingState = newValue
        }
        .onAppear {
            setupAudioSession()
            requestPermissions()
            // Initialize previous recording state to track recording transitions
            previousRecordingState = micController.isRecording
        }
        .onShake {
            handleShake()
        }
        .onDisappear {
            // Save current text before app closes
            saveCurrentTextToHistory()
            speechService.stopRecording()
        }
    }
    
    /// Sets up the audio session for recording
    private func setupAudioSession() {
        do {
            try AudioService.shared.setupAudioSession()
        } catch {
            print("[ContentView] ERROR: Failed to setup audio session: \(error)")
        }
    }
    
    /// Requests microphone and speech recognition permissions
    private func requestPermissions() {
        AudioService.shared.requestMicrophonePermission { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.speechService.requestAuthorization { authorized in
                        if !authorized {
                            print("[ContentView] ERROR: Speech permission denied")
                        }
                    }
                }
            } else {
                print("[ContentView] ERROR: Microphone permission denied")
            }
        }
    }
    
    /// Saves the current text to history if it's valid and different from the last saved caption
    private func saveCurrentTextToHistory() {
        let text = speechService.currentText
        guard !text.isEmpty else { return }
        
        // Check if it's different from the last saved caption
        let lastCaption = historyManager.sortedCaptions.first
        guard lastCaption?.text != text else { return }
        
        let caption = CaptionText(text: text, timestamp: Date(), hasEmojis: true)
        _ = historyManager.addCaption(caption) // Guard rails are checked inside
    }
    
    /// Handles shake gesture to replace text with a pickup line
    /// Feature only available when mic is off, not in keyboard/history views, and cooldown is not active
    private func handleShake() {
        // Feature only available when:
        // - Mic is off
        // - In main content view (not keyboard/history views)
        // - Cooldown is not active
        guard !micController.isRecording,
              !appState.showKeyboard,
              !appState.showHistory,
              !shakeCooldownActive else {
            return
        }
        
        // Enable cooldown immediately to prevent multiple triggers
        shakeCooldownActive = true
        
        // Get shake strength from recently collected motion data
        let shakeStrength = ShakeDetectionService.shared.getShakeStrength()
        
        // Save current text to history before replacing
        if !speechService.currentText.isEmpty {
            saveCurrentTextToHistory()
        }
        
        // Get pickup line based on shake strength
        if let pickupLine = PickupLineService.shared.getPickupLine(shakeStrength: shakeStrength) {
            // Replace current text with pickup line
            speechService.currentText = pickupLine
            
            // Save pickup line to history
            let caption = CaptionText(text: pickupLine, timestamp: Date(), hasEmojis: false)
            _ = historyManager.addCaption(caption)
        }
        
        // Enable 5 second cooldown to prevent rapid successive triggers
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            shakeCooldownActive = false
        }
    }
}

// Extension to detect shake gesture
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetectionModifier(action: action))
    }
}

struct ShakeDetectionModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
