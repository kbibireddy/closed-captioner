//
//  CaptionTextDisplay.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

struct CaptionTextDisplay: View {
    let text: String
    let colorMode: ColorMode
    
    var body: some View {
        Text(text)
            .font(.system(size: calculateFontSize(), weight: .black, design: .default))
            .foregroundColor(colorMode.text)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .frame(maxWidth: .infinity)
            .minimumScaleFactor(0.3)
            .lineSpacing(8)
    }
    
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

