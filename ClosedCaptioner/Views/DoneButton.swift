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
                .font(AppType.display(13, weight: .bold))
                .foregroundColor(appState.colors.onAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(appState.colors.accent)
                .clipShape(Capsule())
        }
    }
}
