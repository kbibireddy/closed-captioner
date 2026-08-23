//
//  SettingsView.swift
//  ClosedCaptioner
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case history
    case purchases

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .history: return "History"
        case .purchases: return "Purchases"
        }
    }

    var systemImage: String {
        switch self {
        case .general: return "circle.lefthalf.filled"
        case .history: return "clock"
        case .purchases: return "cart"
        }
    }

    var selectedSystemImage: String {
        switch self {
        case .general: return "circle.lefthalf.filled"
        case .history: return "clock.fill"
        case .purchases: return "cart.fill"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    @State private var selectedTab: SettingsTab = .history

    var body: some View {
        ZStack {
            appState.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsView(appState: appState)
                    case .history:
                        HistoryContentView(
                            appState: appState,
                            historyManager: historyManager
                        )
                    case .purchases:
                        PurchasesView(appState: appState)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                settingsTabBar
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text("Settings")
                .font(AppType.display(32))
                .tracking(-1.2)
                .foregroundColor(appState.colors.text)

            Spacer()

            DoneButton(
                appState: appState,
                text: "Done",
                onAction: {
                    let wasOnHistory = selectedTab == .history
                    appState.closeSettings()
                    guard wasOnHistory, !PremiumManager.shared.isPremium else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        InterstitialCoordinator.shared.presentAfterHistoryClose()
                    }
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var settingsTabBar: some View {
        HStack(spacing: 4) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == tab ? tab.selectedSystemImage : tab.systemImage)
                            .font(AppType.ui(16, weight: .bold))
                        Text(tab.title)
                            .font(AppType.ui(11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(
                        selectedTab == tab
                            ? appState.colors.onAccent
                            : appState.colors.muted
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedTab == tab
                            ? appState.colors.accent
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
        .padding(5)
        .background(appState.colors.buttonBackground)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }
}
