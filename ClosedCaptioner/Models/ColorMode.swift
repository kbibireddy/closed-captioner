//
//  ColorMode.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import SwiftUI

/// Light or dark appearance. Palette colors come from `AppTheme`.
enum ColorMode: String, CaseIterable {
    case day
    case night

    var title: String {
        switch self {
        case .day:
            return "Day"
        case .night:
            return "Night"
        }
    }

    var icon: String {
        switch self {
        case .day:
            return "sun.max.fill"
        case .night:
            return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .day:
            return .light
        case .night:
            return .dark
        }
    }
}
