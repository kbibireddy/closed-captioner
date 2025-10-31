//
//  HistoryView.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var appState: AppStateViewModel
    @ObservedObject var historyManager: HistoryManager
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var captionToDelete: UUID?
    @State private var selectedCaption: CaptionText?
    
    var body: some View {
        ZStack {
            // Full screen background
            appState.colorMode.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with buttons
                HStack {
                    // Top left: Delete All button (only if more than 1 item) - red with trash icon
                    if historyManager.captions.count > 1 {
                        Button(action: {
                            showDeleteAllConfirmation = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Delete All")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.red)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 9)
                            .background(appState.colorMode.background)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                        .padding()
                    } else {
                        Spacer()
                            .frame(width: 80) // Same width as button for alignment
                            .padding()
                    }
                    
                    Spacer()
                    
                    // Top right: Done button
                    DoneButton(
                        appState: appState,
                        text: "Done",
                        onAction: {
                            appState.toggleHistory()
                        }
                    )
                    .padding()
                }
                
                // History list
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
                }
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a zzz"
        formatter.timeZone = TimeZone.current
        // Use abbreviation style for timezone (e.g., PST, EST)
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: Timestamp (date on one line, time on second)
            VStack(alignment: .leading, spacing: 4) {
                Text(dateFormatter.string(from: caption.timestamp))
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(appState.colorMode.text)
                Text(timeFormatter.string(from: caption.timestamp))
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(appState.colorMode.text.opacity(0.7))
            }
            .frame(width: 120, alignment: .leading)
            
            // Center: Text with emojis
            Text(caption.text)
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundColor(appState.colorMode.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
            
            // Right: Delete button (narrow section with red trash icon)
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
            }
        }
        .padding()
        .background(appState.colorMode.buttonBackground.opacity(0.5))
        .cornerRadius(8)
    }
}

struct HistoryDetailView: View {
    let caption: CaptionText
    @ObservedObject var appState: AppStateViewModel
    let onDone: () -> Void
    
    var body: some View {
        ZStack {
            // Full screen background
            appState.colorMode.background
                .ignoresSafeArea()
            
            VStack {
                // Top section with Done button
                HStack {
                    Spacer()
                    
                    // Done button - top right corner
                    DoneButton(
                        appState: appState,
                        text: "Done",
                        onAction: onDone
                    )
                    .padding()
                }
                
                Spacer()
                
                // Display text like it was originally shown
                CaptionTextDisplay(text: caption.text, colorMode: appState.colorMode)
                
                Spacer()
            }
        }
    }
}

