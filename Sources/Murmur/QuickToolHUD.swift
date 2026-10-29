// SPDX-License-Identifier: GPL-3.0-or-later
// Adapted from Vorssaint's speech-to-text implementation.

import AppKit
import SwiftUI

/// Small floating "Listening…" panel shown for the duration of a push-to-talk
/// capture. Purely visual; never takes focus or intercepts input.
enum QuickToolHUD {
    private static var panel: NSPanel?

    static func showListening(message: String) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { showListening(message: message) }
            return
        }
        let content = HStack(spacing: 8) {
            Image(systemName: "waveform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.red)
            Text(message)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(2)
                .truncationMode(.head)
                .frame(maxWidth: 360, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        let host = NSHostingController(rootView: AnyView(content))
        host.view.layoutSubtreeIfNeeded()
        let size = host.view.fittingSize
        let panel = ensurePanel()
        panel.hasShadow = true
        panel.contentViewController = host
        let frame = screenFrame
        panel.setFrame(NSRect(x: frame.midX - size.width / 2,
                              y: frame.maxY - size.height - 24,
                              width: size.width,
                              height: size.height),
                       display: true)
        if panel.isVisible {
            panel.orderFrontRegardless()
        } else {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                panel.animator().alphaValue = 1
            }
        }
    }

    static func hideListening() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { hideListening() }
            return
        }
        guard let panel else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.contentViewController = nil
        })
    }

    private static var screenFrame: NSRect {
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }
            ?? NSScreen.main
        return screen?.visibleFrame ?? .zero
    }

    private static func ensurePanel() -> NSPanel {
        if let panel { return panel }
        let panel = NSPanel(contentRect: .zero,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        self.panel = panel
        return panel
    }
}
