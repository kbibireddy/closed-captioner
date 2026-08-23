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
            appState.colors.background
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
                    .font(AppType.display(32, weight: .medium))
                    .foregroundColor(appState.colors.text)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding(8)
                    .background(appState.colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                            .stroke(appState.colors.line, lineWidth: 1)
                    )
                    .shadow(color: appState.colors.cardShadow, radius: 18, y: 8)
                    .focused($isFocused)
                    .padding(.horizontal, 20)
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
