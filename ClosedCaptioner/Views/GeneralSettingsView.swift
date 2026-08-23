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
                appearanceSection
                themeSection
            }
            .padding(20)
        }
        .background(appState.colors.background)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Appearance")
                .font(AppType.display(26))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("Day or night. Works with every theme.")
                .font(AppType.ui(14, weight: .medium))
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
                                .font(AppType.ui(14, weight: .bold))
                            Text(mode.title)
                                .font(AppType.ui(15, weight: .bold))
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
                .font(AppType.display(26))
                .tracking(-0.8)
                .foregroundColor(appState.colors.text)

            Text("Grove is the default. Stealth keeps captions hard to read from a distance.")
                .font(AppType.ui(14, weight: .medium))
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
                        .font(AppType.ui(17, weight: .bold))
                        .foregroundColor(appState.colors.text)
                    if theme == .grove {
                        Text("Default")
                            .font(AppType.ui(11, weight: .bold))
                            .foregroundColor(appState.colors.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(appState.colors.accent)
                            .clipShape(Capsule())
                    }
                }
                Text(theme.subtitle)
                    .font(AppType.ui(13, weight: .medium))
                    .foregroundColor(appState.colors.muted)
            }

            Spacer(minLength: 0)

            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                .font(AppType.ui(20, weight: .semibold))
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
