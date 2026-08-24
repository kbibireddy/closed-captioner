//
//  KeyboardEditView.swift
//  ClosedCaptioner
//
//  iMessage-style composer: compact field that grows with lines,
//  send control inside the bubble, X to dismiss, hint in the canvas above.
//

import SwiftUI

struct KeyboardEditView: View {
    @ObservedObject var appState: AppStateViewModel
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    appState.toggleKeyboard()
                } label: {
                    micStyleIcon("xmark")
                }
                .accessibilityLabel("Close keyboard")
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            hint
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            composer
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .background(appState.colors.background.ignoresSafeArea())
        .task {
            try? await Task.sleep(nanoseconds: 10_000_000)
            isFocused = true
        }
        .onAppear {
            isFocused = true
        }
    }

    private var hint: some View {
        VStack(spacing: 12) {
            ViewThatFits(in: .horizontal) {
                sendHintRow
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Press")
                        micStyleIcon("arrow.right", size: 32, fontSize: 13)
                    }
                    Text("to put this text on the canvas.")
                }
            }
            .font(AppType.display(22, weight: .medium))
            .tracking(-0.6)
            .foregroundColor(appState.colors.text)
            .multilineTextAlignment(.center)

            Text("And with Huddle turned on, tap and swipe up to broadcast this message to peers on the Huddle network.")
                .font(AppType.display(17, weight: .medium))
                .tracking(-0.4)
                .foregroundColor(appState.colors.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Press the right arrow to put this text on the canvas. And with Huddle turned on, tap and swipe up to broadcast this message to peers on the Huddle network.")
    }

    private var sendHintRow: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Press")
            micStyleIcon("arrow.right", size: 32, fontSize: 13)
            Text("to put this text on the canvas.")
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var composer: some View {
        HStack(alignment: .center, spacing: 8) {
            TextField("Caption", text: $text, axis: .vertical)
                .font(AppType.display(28, weight: .medium))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)
                .lineLimit(1...6)
                .focused($isFocused)
                .padding(.leading, 14)
                .padding(.vertical, 6)
                .accessibilityLabel("Caption")

            Button(action: onDone) {
                Image(systemName: "arrow.right")
                    .font(AppType.display(13, weight: .bold))
                    .foregroundColor(appState.colors.onAccentFill)
                    .frame(width: 28, height: 28)
                    .background(appState.colors.accentFill)
                    .clipShape(Circle())
            }
            .padding(.trailing, 6)
            .accessibilityLabel("Place caption on canvas")
        }
        .background(appState.colors.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
    }

    /// Same lime chip + ink as the main-screen mic, 10% smaller than chrome (44 → 40).
    private func micStyleIcon(
        _ systemName: String,
        size: CGFloat = 40,
        fontSize: CGFloat = 16
    ) -> some View {
        Image(systemName: systemName)
            .font(AppType.display(fontSize, weight: .bold))
            .foregroundColor(appState.colors.onAccentFill)
            .frame(width: size, height: size)
            .background(appState.colors.accentFill)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(appState.colors.line, lineWidth: 1)
            )
            .shadow(color: appState.colors.cardShadow, radius: 11, y: 5)
    }
}
