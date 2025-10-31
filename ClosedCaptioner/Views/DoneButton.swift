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
    
    // Reduced by 25%: 20 * 0.75 = 15, 12 * 0.75 = 9, 20 * 0.75 = 15, 12 * 0.75 = 9
    var body: some View {
        Button(action: onAction) {
            Text(text)
                .font(.system(size: 15, weight: .semibold)) // 20 * 0.75
                .foregroundColor(appState.colorMode.text)
                .padding(.horizontal, 15) // 20 * 0.75
                .padding(.vertical, 9) // 12 * 0.75
                .background(appState.colorMode.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(appState.colorMode.text, lineWidth: 1)
                )
        }
    }
}

