//
//  ControlsView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct ControlsView: View {
    @ObservedObject var micController: MicController
    @ObservedObject var appState: AppStateViewModel
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
                        Image(systemName: "keyboard")
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
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(2)
            
            // Bottom buttons
            VStack {
                Spacer()
                
                HStack {
                    // Bottom left: Mic button - press and hold
                    Button(action: {
                        if !micController.isRecording {
                            micController.startRecording()
                        } else {
                            micController.stopRecording()
                        }
                    }) {
                        Image(systemName: micController.isRecording ? "mic.fill" : "mic")
                            .font(.title)
                            .foregroundColor(appState.colorMode.text)
                            .padding()
                            .background(
                                micController.isRecording 
                                    ? Color.red.opacity(0.7)
                                    : appState.colorMode.buttonBackground
                            )
                            .clipShape(Circle())
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                // Keep recording while dragging
                            }
                            .onEnded { _ in
                                // Stop when released
                                if micController.isRecording {
                                    micController.stopRecording()
                                }
                            }
                    )
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { isPressing in
                        if isPressing {
                            // Finger pressed down - start recording
                            micController.startRecording()
                        } else {
                            // Finger released - stop recording
                            micController.stopRecording()
                        }
                    }, perform: {})
                    
                    Spacer()
                    
                    // Bottom right: Erase button
                    Button(action: onClear) {
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

