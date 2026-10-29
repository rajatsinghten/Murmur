// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from Vorssaint's speech-to-text implementation.

import AppKit
import ApplicationServices
import AVFoundation
import Speech

/// The three permissions voice typing needs: microphone, speech recognition
/// and accessibility (to paste the finished text into the frontmost app).
final class Permissions {
    static let shared = Permissions()

    private init() {}

    var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestMicrophone(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func requestSpeechRecognition(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async { completion(status == .authorized) }
        }
    }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
