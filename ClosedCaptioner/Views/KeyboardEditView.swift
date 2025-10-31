//
//  KeyboardEditView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct KeyboardEditView: View {
    @ObservedObject var appState: AppStateViewModel
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    let onDone: () -> Void
    
    var body: some View {
        ZStack {
            // Full screen background
            appState.colorMode.background
                .ignoresSafeArea()
            
            VStack {
                // Top section with Done button
                HStack {
                    Spacer()
                    
                    // Done button - top right corner (reusable component)
                    DoneButton(
                        appState: appState,
                        text: "Done",
                        onAction: onDone
                    )
                    .padding()
                }
                
                Spacer()
                
                // Text editor - centered
                TextEditor(text: $text)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(appState.colorMode.text)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding()
                    .background(appState.colorMode.background)
                    .cornerRadius(8)
                    .focused($isFocused)
                    .padding(.horizontal)
                    .onTapGesture {
                        // Ensure focus if tapped
                        isFocused = true
                    }
                
                Spacer()
            }
        }
        .task {
            // Set focus after view is laid out - task ensures view is ready
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms minimal delay for layout
            isFocused = true
        }
        .onAppear {
            // Set focus immediately when view appears
            isFocused = true
        }
    }
}

