//
//  MicControlProtocol.swift
//  ClosedCaptioner
//
//  Created by Karthik Bibireddy on 10/27/25.
//

import Foundation
import Combine

protocol MicControlProtocol {
    var isRecording: Bool { get }
    func startRecording()
    func stopRecording()
}

extension MicControlProtocol {
    var isNotRecording: Bool {
        !isRecording
    }
}

