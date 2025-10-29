//
//  ContentView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var speechService = SpeechService()
    @StateObject private var appState = AppStateViewModel()
    @StateObject private var micController: MicController
    @State private var editedText = ""
    
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
                    appState.clearScreen()
                    speechService.currentText = ""
                }
            )
            
            // Text display or editor (center)
            VStack {
                Spacer()
                
                if appState.showKeyboard {
                    ZStack {
                        // Background - tapable to close
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                appState.toggleKeyboard()
                            }
                        
                        TextEditor(text: $editedText)
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(appState.colorMode.text)
                            .scrollContentBackground(.hidden)
                            .frame(height: 200)
                            .padding()
                            .background(appState.colorMode.background)
                            .onTapGesture {
                                // Prevent closing when tapping editor
                            }
                    }
                    .onAppear {
                        editedText = speechService.currentText
                    }
                    .onDisappear {
                        speechService.currentText = editedText
                    }
                } else if appState.showPoofAnimation {
                    // Show POOF animation
                    Text("✨Poof!!!✨")
                        .font(.system(size: 80, weight: .black, design: .default))
                        .foregroundColor(appState.colorMode.text)
                        .opacity(appState.poofOpacity)
                } else {
                    // Only show text if there's actual content
                    if !speechService.currentText.isEmpty {
                        CaptionTextDisplay(text: speechService.currentText, colorMode: appState.colorMode)
                    } else if micController.isRecording {
                        // Show recording indicator
                        Text("🎤 Listening...")
                            .font(.system(size: 60, weight: .black, design: .default))
                            .foregroundColor(appState.colorMode.text.opacity(0.5))
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(1)
        }
        .onAppear {
            setupAudioSession()
            requestPermissions()
        }
        .onDisappear {
            speechService.stopRecognition()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AudioService.shared.setupAudioSession()
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func requestPermissions() {
        AudioService.shared.requestMicrophonePermission { allowed in
            if allowed {
                DispatchQueue.main.async {
                    self.speechService.requestAuthorization { authorized in
                        if !authorized {
                            print("Speech permission denied")
                        }
                    }
                }
            } else {
                print("Microphone permission denied")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
