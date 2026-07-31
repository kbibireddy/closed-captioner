//
//  SettingsView.swift
//  ClosedCaptioner
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable {
    case history
    case purchases

    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: return "History"
        case .purchases: return "Purchases"
        }
    }

    var systemImage: String {
        switch self {
        case .history: return "clock"
        case .purchases: return "cart"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    @State private var selectedTab: SettingsTab = .history

    var body: some View {
        ZStack {
            appState.colorMode.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                Group {
                    switch selectedTab {
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
        HStack {
            Text("Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(appState.colorMode.text)

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
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    /// Instagram-style bottom menu for History / Purchases.
    private var settingsTabBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(appState.colorMode.text.opacity(0.2))

            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? "\(tab.systemImage).fill" : tab.systemImage)
                                .font(.system(size: 22, weight: .regular))
                            Text(tab.title)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(
                            selectedTab == tab
                                ? appState.colorMode.text
                                : appState.colorMode.text.opacity(0.45)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .accessibilityLabel(tab.title)
                }
            }
            .padding(.horizontal, 8)
            .background(appState.colorMode.background)
        }
    }
}
