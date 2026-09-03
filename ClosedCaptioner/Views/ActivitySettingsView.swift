//
//  ActivitySettingsView.swift
//  ClosedCaptioner
//
//  Settings → Activity: Captions history + Huddle log in one tab.
//

import SwiftUI

enum ActivityPane: String, CaseIterable, Identifiable {
    case captions
    case huddle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .captions: return "Text"
        case .huddle: return "Gossip"
        }
    }

    var icon: String {
        switch self {
        case .captions: return "text.alignleft"
        case .huddle: return "antenna.radiowaves.left.and.right"
        }
    }
}

struct ActivitySettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    let p2pInbox: P2PInboxService
    var onCaptionsVisibilityChange: ((Bool) -> Void)?
    @State private var pane: ActivityPane = .captions

    var body: some View {
        VStack(spacing: 0) {
            paneSwitcher
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 12)

            Group {
                switch pane {
                case .captions:
                    HistoryContentView(
                        appState: appState,
                        historyManager: historyManager
                    )
                case .huddle:
                    HuddleLogsSettingsView(
                        appState: appState,
                        p2pInbox: p2pInbox
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(appState.colors.background)
        .onAppear {
            onCaptionsVisibilityChange?(pane == .captions)
        }
        .onChange(of: pane) { newValue in
            onCaptionsVisibilityChange?(newValue == .captions)
        }
    }

    private var paneSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(ActivityPane.allCases) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pane = option
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: option.icon)
                            .font(AppType.display(14, weight: .bold))
                        Text(option.title)
                            .font(AppType.display(13, weight: .bold))
                    }
                    .foregroundColor(
                        pane == option
                            ? appState.colors.onAccent
                            : appState.colors.muted
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        pane == option
                            ? appState.colors.accent
                            : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(pane == option ? .isSelected : [])
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

/// Plain log-file style list of Huddle messages.
struct HuddleLogsSettingsView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject private var log: P2PMessageLog

    init(appState: AppStateViewModel, p2pInbox: P2PInboxService) {
        self.appState = appState
        _log = ObservedObject(wrappedValue: p2pInbox.log)
    }

    private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    var body: some View {
        Group {
            if log.messages.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No Gossip messages yet")
                        .font(AppType.display(22))
                        .tracking(-0.6)
                        .foregroundColor(appState.colors.muted)
                    Text("Turn Gossip on to collect the live 200-message buffer.")
                        .font(AppType.display(13, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Ordered messages on the Gossip network, including your own.")
                        .font(AppType.display(13, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                    Text("datetime  author  from  message")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(appState.colors.muted)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(log.messages.enumerated()), id: \.element.id) { index, entry in
                                    if index > 0 {
                                        Rectangle()
                                            .fill(appState.colors.line.opacity(0.55))
                                            .frame(height: 1)
                                    }
                                    logLine(entry)
                                        .id(entry.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                        }
                        .onAppear { scrollToEnd(proxy) }
                        .onChange(of: log.messages.last?.id) { _ in
                            scrollToEnd(proxy)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appState.colors.background)
        .accessibilityLabel("Gossip message logs")
    }

    private func logLine(_ entry: P2PLogEntry) -> some View {
        let author = authorLabel(for: entry)
        let neighbor = entry.neighborName ?? "—"
        let stamp = Self.stampFormatter.string(from: entry.receivedAt)

        return (
            Text(stamp)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(appState.colors.muted)
            + Text("  ")
            + Text(author)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(appState.colors.text)
            + Text("  ")
            + Text(neighbor)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(appState.colors.muted)
            + Text("  ")
            + Text(entry.text)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(appState.colors.text)
        )
        .fixedSize(horizontal: false, vertical: true)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("\(stamp), \(author), from \(neighbor), \(entry.text)")
    }

    private func authorLabel(for entry: P2PLogEntry) -> String {
        let mine = P2PConfig.normalizedName(appState.displayName) ?? appState.displayName
        if entry.senderName.caseInsensitiveCompare(mine) == .orderedSame {
            return "You"
        }
        return entry.senderName
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        guard let lastID = log.messages.last?.id else { return }
        DispatchQueue.main.async {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}
