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
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10.2, weight: .semibold))
                            Text("Delete All")
                                .font(.system(size: 12.75, weight: .semibold))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12.75)
                        .padding(.vertical, 7.65)
                        .background(appState.colorMode.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                }

                Spacer()
            }

            if historyManager.sortedCaptions.isEmpty {
                Spacer()
                Text("No history yet")
                    .font(.system(size: 24, weight: .medium, design: .default))
                    .foregroundColor(appState.colorMode.text.opacity(0.5))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
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
                    .padding()
                }
                .background(appState.colorMode.background)
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
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(appState.colorMode.text)
                Text(Self.timeFormatter.string(from: caption.timestamp))
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(appState.colorMode.text.opacity(0.7))
            }
            .frame(width: 120, alignment: .leading)

            Text(caption.text)
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(appState.colorMode.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
            }
        }
        .padding()
        .background(appState.colorMode.buttonBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appState.colorMode.text.opacity(0.2), lineWidth: 1)
        )
    }
}

struct HistoryDetailView: View {
    let caption: CaptionText
    @ObservedObject var appState: AppStateViewModel
    let onDone: () -> Void

    var body: some View {
        ZStack {
            appState.colorMode.background
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
                CaptionTextDisplay(text: caption.text, colorMode: appState.colorMode)
                Spacer()
            }
        }
    }
}
