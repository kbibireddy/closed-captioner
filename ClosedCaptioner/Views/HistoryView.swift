//
//  HistoryView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// History list content used inside Settings (and formerly as a standalone overlay).
struct HistoryContentView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var captionToDelete: UUID?
    @State private var selectedCaption: CaptionText?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if historyManager.captions.count > 1 {
                    Button(action: {
                        showDeleteAllConfirmation = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(AppType.display(11, weight: .bold))
                            Text("Delete All")
                                .font(AppType.display(12, weight: .bold))
                        }
                        .foregroundColor(appState.colors.danger)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(appState.colors.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(appState.colors.danger.opacity(0.7), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }

                Spacer()
            }

            if historyManager.sortedCaptions.isEmpty {
                Spacer()
                Text("No history yet")
                    .font(AppType.display(22))
                    .tracking(-0.8)
                    .foregroundColor(appState.colors.muted)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(historyManager.sortedCaptions) { caption in
                            HistoryRow(
                                caption: caption,
                                appState: appState,
                                onTap: {
                                    selectedCaption = caption
                                },
                                onDelete: {
                                    captionToDelete = caption.id
                                    showDeleteConfirmation = true
                                }
                            )
                        }
                    }
                    .padding(20)
                }
                .background(appState.colors.background)
            }
        }
        .alert("Delete All History?", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                historyManager.clearHistory()
            }
        } message: {
            Text("This will permanently delete all history items. This action cannot be undone.")
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let id = captionToDelete {
                    historyManager.removeCaption(id: id)
                }
            }
        } message: {
            Text("This will permanently delete this history item. This action cannot be undone.")
        }
        .sheet(item: $selectedCaption) { caption in
            HistoryDetailView(
                caption: caption,
                appState: appState,
                onDone: {
                    selectedCaption = nil
                }
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
        formatter.dateFormat = "h:mm a zzz"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Self.dateFormatter.string(from: caption.timestamp))
                    .font(AppType.display(11, weight: .bold))
                    .foregroundColor(appState.colors.text)
                Text(Self.timeFormatter.string(from: caption.timestamp))
                    .font(AppType.display(10, weight: .medium))
                    .foregroundColor(appState.colors.muted)
            }
            .frame(width: 110, alignment: .leading)

            Text(caption.text)
                .font(AppType.display(16))
                .tracking(-0.4)
                .foregroundColor(appState.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(AppType.display(13, weight: .semibold))
                    .foregroundColor(appState.colors.danger)
                    .frame(width: 30, height: 30)
            }
        }
        .appCard(for: appState.colors)
    }
}

struct HistoryDetailView: View {
    let caption: CaptionText
    @ObservedObject var appState: AppStateViewModel
    let onDone: () -> Void

    var body: some View {
        ZStack {
            appState.colors.background
                .ignoresSafeArea()

            VStack {
                HStack {
                    Spacer()
                    DoneButton(
                        appState: appState,
                        text: "Done",
                        onAction: onDone
                    )
                    .padding()
                }

                Spacer()
                CaptionTextDisplay(text: caption.text, colors: appState.colors)
                Spacer()
            }
        }
    }
}
