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

    var body: some View {
        Button(action: onAction) {
            Text(text)
                .font(AppType.ui(15, weight: .bold))
                .foregroundColor(appState.colors.onAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(appState.colors.accent)
                .clipShape(Capsule())
        }
    }
}
