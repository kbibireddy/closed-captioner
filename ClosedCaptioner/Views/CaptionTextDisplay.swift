//
//  CaptionTextDisplay.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// View that displays caption text with adaptive font sizing based on text length
struct CaptionTextDisplay: View {
    /// The text to display
    let text: String
    /// Resolved palette for text color
    let colors: ThemeColors

    var body: some View {
        Text(text)
            .font(AppType.display(calculateFontSize(), weight: .medium))
            .tracking(-1.6)
            .foregroundColor(colors.text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.3)
            .lineSpacing(4)
    }

    /// Calculates appropriate font size based on text length
    /// Longer text gets progressively smaller font to fit on screen
    /// - Returns: The calculated font size in points
    private func calculateFontSize() -> CGFloat {
        let baseSize: CGFloat = 80 // Large size for 4-6 words in landscape
        let textLength = text.count

        // Reduce size proportionally as text gets longer
        if textLength <= 30 {
            return baseSize
        } else if textLength <= 60 {
            return baseSize * 0.8
        } else if textLength <= 100 {
            return baseSize * 0.65
        } else if textLength <= 150 {
            return baseSize * 0.5
        } else {
            return baseSize * 0.4
        }
    }
}
