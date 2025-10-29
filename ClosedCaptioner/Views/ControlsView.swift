//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct ControlsView: View {
    @ObservedObject var speechService: SpeechService
    @ObservedObject var appState: AppStateViewModel
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        ZStack {
            // Top buttons
            VStack {
                HStack {
                    // Top left: Keyboard button
                    Button(action: {
                        appState.toggleKeyboard()
                    }) {
                        Image(systemName: appState.showKeyboard ? "keyboard" : "keyboard")
                            .font(.title2)
                            .foregroundColor(appState.colorMode.text)
                            .padding()
                            .background(
                                appState.showKeyboard 
                                    ? Color.blue.opacity(0.5)
                                    : appState.colorMode.buttonBackground
                            )
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Top right: Display mode picker
                    Picker("Color Mode", selection: $appState.colorMode) {
                        ForEach(ColorMode.allCases, id: \.self) { mode in
                            Image(systemName: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .tint(appState.colorMode.text.opacity(0.3))
                    .colorMultiply(appState.colorMode.text)
                }
                .padding()
                .zIndex(2)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(2)
            
            // Bottom buttons
            VStack {
                Spacer()
                
                HStack {
                    // Bottom left: Mic button
                    Button(action: {
                        if !speechService.isRecording {
                            onStartRecording()
                        } else {
                            onStopRecording()
                        }
                    }) {
                        Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                            .font(.title)
                            .foregroundColor(appState.colorMode.text)
                            .padding()
                            .background(
                                speechService.isRecording 
                                    ? Color.red.opacity(0.7)
                                    : appState.colorMode.buttonBackground
                            )
                            .clipShape(Circle())
                    }
                    .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 0) {
                        // Empty handler for tap detection
                    } onPressingChanged: { pressing in
                        if pressing {
                            // Finger down
                            if !speechService.isRecording {
                                onStartRecording()
                            }
                        } else {
                            // Finger up
                            if speechService.isRecording {
                                onStopRecording()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom right: Erase button
                    Button(action: {
                        onClear()
                    }) {
                        Image(systemName: "eraser.fill")
                            .font(.title)
                            .foregroundColor(appState.colorMode.text)
                            .padding()
                            .background(appState.colorMode.buttonBackground)
                            .clipShape(Circle())
                    }
                }
                .padding()
                .zIndex(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

