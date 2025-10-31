//
//  DoneButton.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct DoneButton: View {
    @ObservedObject var appState: AppStateViewModel
    let text: String
    let onAction: () -> Void
    
    // Reduced by 25% then 15% more: 15 * 0.85 = 12.75, 9 * 0.85 = 7.65
    var body: some View {
        Button(action: onAction) {
            Text(text)
                .font(.system(size: 12.75, weight: .semibold)) // 15 * 0.85
                .foregroundColor(appState.colorMode.text)
                .padding(.horizontal, 12.75) // 15 * 0.85
                .padding(.vertical, 7.65) // 9 * 0.85
                .background(appState.colorMode.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(appState.colorMode.text, lineWidth: 1)
                )
        }
    }
}

