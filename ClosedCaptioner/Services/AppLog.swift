//
//  AppLog.swift
//  ClosedCaptioner
//

import Foundation

/// Debug-only logging. Release builds compile these calls out (autoclosure is not evaluated).
enum AppLog {
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print(message())
        #endif
    }
}
