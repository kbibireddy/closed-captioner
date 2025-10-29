//
//  ColorMode.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

enum ColorMode: String, CaseIterable {
    case day
    case night
    case discreet
    
    var background: Color {
        switch self {
        case .day:
            return .white
        case .night:
            return .black
        case .discreet:
            return Color(red: 0.1, green: 0.1, blue: 0.1) // Very dark gray
        }
    }
    
    var text: Color {
        switch self {
        case .day:
            return .black
        case .night:
            return .white
        case .discreet:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Slightly lighter gray - very low contrast
        }
    }
    
    var icon: String {
        switch self {
        case .day:
            return "sun.max.fill"
        case .night:
            return "moon.fill"
        case .discreet:
            return "eye.slash.fill"
        }
    }
    
    var buttonBackground: Color {
        switch self {
        case .day:
            return Color.gray.opacity(0.3)
        case .night:
            return Color.gray.opacity(0.3)
        case .discreet:
            return Color.gray.opacity(0.5)
        }
    }
}

