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
            // Top section - history button (left) and display mode picker (right)
            VStack {
                HStack {
                    // Top left: History button (icon only, no circular background)
                    Button(action: {
                        appState.toggleHistory()
                    }) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(appState.colorMode.text)
                    }
                    .padding()
                    
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
            
            // Bottom buttons - keyboard (left), mic (center), erase (right)
            VStack {
                Spacer()
                
                HStack {
                    // Bottom left: Keyboard button - always same appearance
                    Button(action: {
                        appState.toggleKeyboard()
                    }) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 19.8)) // .title2 reduced by 10% (22 * 0.9)
                            .foregroundColor(appState.colorMode.text)
                            .padding(18) // Reduced by 10% (20 * 0.9)
                            .background(appState.colorMode.buttonBackground)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Bottom center: Mic button - start on release, kill on tap during recording
                    Image(systemName: micController.isRecording ? "stop.fill" : "mic")
                        .font(.system(size: 25.2)) // .title reduced by 10% (28 * 0.9)
                        .foregroundColor(micController.isRecording ? .black : appState.colorMode.text)
                        .padding(18) // Reduced by 10% (20 * 0.9)
                        .background(
                            micController.isRecording 
                                ? Color.red
                                : appState.colorMode.buttonBackground
                        )
                        .clipShape(Circle())
                        .contentShape(Circle())
                        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                            // Do nothing on press
                        }, perform: {
                            if micController.isRecording {
                                // Kill command: stop recording immediately
                                micController.stopRecording()
                            } else {
                                // Start recording on release (tap, long press, or drag end)
                                micController.startRecording()
                            }
                        })
                    
                    Spacer()
                    
                    // Bottom right: Erase button
                    Button(action: onClear) {
                        Image(systemName: "eraser.fill")
                            .font(.system(size: 25.2)) // .title reduced by 10% (28 * 0.9)
                            .foregroundColor(appState.colorMode.text)
                            .padding(18) // Reduced by 10% (20 * 0.9)
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

