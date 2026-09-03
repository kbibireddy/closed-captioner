//
//  HistoryView.swift
//  ClosedCaptioner
//
//  Activity → Captions history (canvas entries) and detail sheet.
//

import SwiftUI

/// Captions pane inside Settings → Activity.
struct HistoryContentView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var captionToDelete: UUID?
    @State private var selectedCaption: CaptionText?

    var body: some View {
        VStack(spacing: 0) {
            if !historyManager.sortedCaptions.isEmpty {
                HStack {
                    Text("A history of text that reached the canvas.")
                        .font(AppType.display(13, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                    Spacer(minLength: 8)
                    if historyManager.captions.count > 1 {
                        Button {
                            showDeleteAllConfirmation = true
                        } label: {
                            Text("Clear all")
                                .font(AppType.display(12, weight: .bold))
                                .foregroundColor(appState.colors.danger)
                        }
                        .accessibilityLabel("Clear all text history")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 10)
            }

            if historyManager.sortedCaptions.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("No text yet")
                        .font(AppType.display(22))
                        .tracking(-0.8)
                        .foregroundColor(appState.colors.muted)
                    Text("Speech, typing, and shake lines show up here.")
                        .font(AppType.display(14, weight: .medium))
                        .foregroundColor(appState.colors.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView(.vertical) {
                    LazyVStack(spacing: 12) {
                        ForEach(historyManager.sortedCaptions) { caption in
                            HistoryRow(
                                caption: caption,
                                appState: appState,
                                onTap: { selectedCaption = caption },
                                onDelete: {
                                    captionToDelete = caption.id
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                }
                .verticalScrollLocked()
                .background(appState.colors.background)
            }
        }
        .alert("Clear all text?", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear all", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("This permanently deletes every entry in history.")
        }
        .alert("Delete this text?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = captionToDelete {
                    historyManager.removeCaption(id: id)
                }
            }
        } message: {
            Text("This entry will be removed from history.")
        }
        .sheet(item: $selectedCaption) { caption in
            HistoryDetailView(
                caption: caption,
                appState: appState,
                onDone: { selectedCaption = nil }
            )
        }
    }
}

struct HistoryRow: View {
    let caption: CaptionText
    @ObservedObject var appState: AppStateViewModel
    let onTap: () -> Void
    let onDelete: () -> Void

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Self.dateFormatter.string(from: caption.timestamp))
                    .font(AppType.display(11, weight: .bold))
                    .foregroundColor(appState.colors.text)
                Text(Self.timeFormatter.string(from: caption.timestamp))
                    .font(AppType.display(11, weight: .medium))
                    .foregroundColor(appState.colors.muted)
            }
            .frame(width: 88, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Text(caption.text)
                    .font(AppType.display(16))
                    .tracking(-0.4)
                    .foregroundColor(appState.colors.text)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(caption.source.chipTitle)
                    .font(AppType.display(11, weight: .bold))
                    .foregroundColor(appState.colors.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appState.colors.accent)
                    .clipShape(Capsule())
                    .accessibilityLabel(caption.source.accessibilityTitle)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(AppType.display(13, weight: .semibold))
                    .foregroundColor(appState.colors.danger)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete text")
        }
        .padding(14)
        .background(appState.colors.card)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(appState.colors.line, lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(caption.source.accessibilityTitle), \(caption.text)")
        .accessibilityHint("Opens text")
        .accessibilityAction(named: "Open") { onTap() }
    }
}

struct HistoryDetailView: View {
    let caption: CaptionText
    @ObservedObject var appState: AppStateViewModel
    let onDone: () -> Void

    private static let stampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy · h:mm a"
        return formatter
    }()

    var body: some View {
        ZStack {
            appState.colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Self.stampFormatter.string(from: caption.timestamp))
                            .font(AppType.display(12, weight: .medium))
                            .foregroundColor(appState.colors.muted)
                        Text(caption.source.accessibilityTitle)
                            .font(AppType.display(11, weight: .bold))
                            .foregroundColor(appState.colors.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(appState.colors.accent)
                            .clipShape(Capsule())
                    }
                    Spacer()
                    DoneButton(
                        appState: appState,
                        text: "Done",
                        onAction: onDone
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Spacer()
                CaptionTextDisplay(text: caption.text, colors: appState.colors)
                Spacer()
            }
        }
    }
}
