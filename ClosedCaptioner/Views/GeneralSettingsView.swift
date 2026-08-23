//
//  GeneralSettingsView.swift
//  ClosedCaptioner
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var appState: AppStateViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                userInfoSection
                nearbySection
                appearanceSection
                themeSection
            }
            .padding(20)
        }
        .background(appState.colors.background)
        .onDisappear {
            appState.commitDisplayName()
        }
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("User info")
                .font(AppType.display(22))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("This name is shown on nearby messages you send. It starts as this device’s host name.")
                .font(AppType.display(14, weight: .medium))
                .foregroundColor(appState.colors.muted)
                .padding(.bottom, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Display name")
                    .font(AppType.display(13, weight: .bold))
                    .foregroundColor(appState.colors.muted)

                TextField(AppStateViewModel.hostDisplayName(), text: $appState.displayName)
                    .font(AppType.display(15, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.colors.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.control, style: .continuous)
                            .stroke(appState.colors.line, lineWidth: 1)
                    )
                    .onChange(of: appState.displayName) { newValue in
                        if newValue.count > P2PConfig.maxDisplayNameLength {
                            appState.displayName = String(newValue.prefix(P2PConfig.maxDisplayNameLength))
                        }
                    }
                    .onSubmit {
                        appState.commitDisplayName()
                    }
                    .submitLabel(.done)
            }
        }
    }

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nearby")
                .font(AppType.display(22))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("When radio is on, this phone can pass a caption to the next person nearby. Delivery isn’t guaranteed.")
                .font(AppType.display(14, weight: .medium))
                .foregroundColor(appState.colors.muted)
                .padding(.bottom, 4)

            Toggle(isOn: $appState.relayMessages) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Relay messages")
                        .font(AppType.display(15, weight: .semibold))
                        .foregroundColor(appState.colors.text)
                    Text("Off by default. Uses extra Bluetooth or Wi‑Fi only while radio is on.")
                        .font(AppType.display(13, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                }
            }
            .tint(appState.colors.accent)
            .accessibilityLabel("Relay messages")
            .accessibilityHint("Forwards nearby captions so they can reach people farther away. Radio must also be on.")

            VStack(alignment: .leading, spacing: 8) {
                Text("Keep radio nearby")
                    .font(AppType.display(15, weight: .semibold))
                    .foregroundColor(appState.colors.text)
                Text("Stays on if you switch apps or lock the phone. Stops when you turn radio off, close the app, or this timer ends. iOS may still pause it to save battery.")
                    .font(AppType.display(13, weight: .medium))
                    .foregroundColor(appState.colors.muted)

                HStack(spacing: 4) {
                    ForEach(RadioKeepAlive.allCases) { option in
                        Button {
                            appState.radioKeepAlive = option
                        } label: {
                            Text(option.title)
                                .font(AppType.display(11, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundColor(
                                    appState.radioKeepAlive == option
                                        ? appState.colors.onAccent
                                        : appState.colors.muted
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    appState.radioKeepAlive == option
                                        ? appState.colors.accent
                                        : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .accessibilityLabel(option.title)
                        .accessibilityAddTraits(appState.radioKeepAlive == option ? .isSelected : [])
                    }
                }
                .padding(4)
                .background(appState.colors.buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(appState.colors.line, lineWidth: 1)
                )
            }
            .padding(.top, 8)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(AppType.display(22))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("Day or night. Works with every theme.")
                .font(AppType.display(14, weight: .medium))
                .foregroundColor(appState.colors.muted)
                .padding(.bottom, 4)

            HStack(spacing: 4) {
                ForEach(ColorMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            appState.colorMode = mode
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(AppType.display(14, weight: .bold))
                            Text(mode.title)
                                .font(AppType.display(13, weight: .bold))
                        }
                        .foregroundColor(
                            appState.colorMode == mode
                                ? appState.colors.onAccent
                                : appState.colors.muted
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            appState.colorMode == mode
                                ? appState.colors.accent
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .accessibilityLabel(mode.title)
                    .accessibilityAddTraits(appState.colorMode == mode ? .isSelected : [])
                }
            }
            .padding(5)
            .background(appState.colors.buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(appState.colors.line, lineWidth: 1)
            )
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme")
                .font(AppType.display(22))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("Grove is the default. Stealth keeps captions hard to read from a distance.")
                .font(AppType.display(14, weight: .medium))
                .foregroundColor(appState.colors.muted)
                .padding(.bottom, 4)

            ForEach(AppTheme.allCases) { theme in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.theme = theme
                    }
                } label: {
                    themeRow(theme)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.title)
                .accessibilityAddTraits(appState.theme == theme ? .isSelected : [])
            }
        }
    }

    private func themeRow(_ theme: AppTheme) -> some View {
        let selected = appState.theme == theme
        return HStack(spacing: 14) {
            HStack(spacing: 5) {
                ForEach(Array(theme.previewSwatches.enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 18, height: 18)
                        .overlay(Circle().stroke(appState.colors.line, lineWidth: 0.5))
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(theme.title)
                        .font(AppType.display(15, weight: .bold))
                        .foregroundColor(appState.colors.text)
                    if theme == .grove {
                        Text("Default")
                            .font(AppType.display(11, weight: .bold))
                            .foregroundColor(appState.colors.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(appState.colors.accent)
                            .clipShape(Capsule())
                    }
                }
                Text(theme.subtitle)
                    .font(AppType.display(13, weight: .medium))
                    .foregroundColor(appState.colors.muted)
            }

            Spacer(minLength: 0)

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(AppType.display(20, weight: .semibold))
                .foregroundColor(selected ? appState.colors.accent : appState.colors.muted)
        }
        .padding(14)
        .background(appState.colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(selected ? appState.colors.accent : appState.colors.line, lineWidth: selected ? 2 : 1)
        )
    }
}
