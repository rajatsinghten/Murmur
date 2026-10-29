// SPDX-License-Identifier: MIT

import AppKit
import Carbon.HIToolbox

/// Small key window that records the next key combination as a global shortcut.
final class ShortcutRecorderWindowController: NSWindowController, NSWindowDelegate {
    var onRecord: ((GlobalShortcut) -> Void)?
    var onClose: (() -> Void)?

    private let statusLabel = NSTextField(labelWithString: "")
    private var monitor: Any?

    init(current: GlobalShortcut) {
        let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 320, height: 140),
                            styleMask: [.titled, .closable],
                            backing: .buffered,
                            defer: false)
        panel.title = "Change Shortcut"
        panel.isReleasedWhenClosed = false
        super.init(window: panel)
        window?.delegate = self

        let title = NSTextField(labelWithString: "Press the new shortcut")
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.alignment = .center

        statusLabel.stringValue = "Current: \(current.displayString)"
        statusLabel.font = .systemFont(ofSize: 12)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center

        let cancel = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancel.bezelStyle = .rounded

        let stack = NSStackView(views: [title, statusLabel, cancel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        panel.contentView = container
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        guard let window else { return }
        NSApp.activate(ignoringOtherApps: true)
        window.center()
        window.makeKeyAndOrderFront(nil)
        installMonitor()
    }

    private func installMonitor() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            if self.handle(event) { return nil }
            return event
        }
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func handle(_ event: NSEvent) -> Bool {
        if event.keyCode == UInt16(kVK_Escape) {
            cancel()
            return true
        }
        let modifiers = GlobalShortcutModifiers(eventFlags: event.modifierFlags)
        let shortcut = GlobalShortcut(keyCode: Int64(event.keyCode), modifiers: modifiers)
        guard shortcut.isValid else { return true }
        finish(with: shortcut)
        return true
    }

    private func finish(with shortcut: GlobalShortcut) {
        removeMonitor()
        onRecord?(shortcut)
        closeAndNotify()
    }

    @objc private func cancel() {
        removeMonitor()
        closeAndNotify()
    }

    private func closeAndNotify() {
        window?.orderOut(nil)
        onClose?()
    }

    func windowWillClose(_ notification: Notification) {
        removeMonitor()
        onClose?()
    }
}
