// SPDX-License-Identifier: MIT

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private let menu = NSMenu()
    private let hintItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let startItem = NSMenuItem(title: "Start Dictation", action: #selector(startDictation), keyEquivalent: "")
    private let stopItem = NSMenuItem(title: "Stop Dictation", action: #selector(stopDictation), keyEquivalent: "")
    private let changeShortcutItem = NSMenuItem(title: "Change Shortcut…", action: #selector(changeShortcut), keyEquivalent: "")
    private let showInMenuBarItem = NSMenuItem(title: "Show in Menu Bar", action: #selector(toggleMenuBarIcon), keyEquivalent: "")
    private let service = SpeechToTextService.shared
    private var shortcutRecorder: ShortcutRecorderWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        Defaults.register()
        service.syncWithPreferences()
        configureMenu()
        applyMenuBarIconVisibility()
    }

    func applicationWillTerminate(_ notification: Notification) {
        service.suspend()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if UserDefaults.standard.bool(forKey: DefaultsKey.menuBarIconHidden) {
            UserDefaults.standard.set(false, forKey: DefaultsKey.menuBarIconHidden)
            applyMenuBarIconVisibility()
        }
        return true
    }

    private func configureMenu() {
        menu.delegate = self
        hintItem.isEnabled = false
        startItem.target = self
        stopItem.target = self
        changeShortcutItem.target = self
        showInMenuBarItem.target = self

        menu.addItem(hintItem)
        menu.addItem(.separator())
        menu.addItem(startItem)
        menu.addItem(stopItem)
        menu.addItem(.separator())
        menu.addItem(changeShortcutItem)
        menu.addItem(showInMenuBarItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Murmur", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    private func makeStatusItem() -> NSStatusItem {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Murmur")
            image?.isTemplate = true
            button.image = image
        }
        item.menu = menu
        return item
    }

    private func applyMenuBarIconVisibility() {
        let hidden = UserDefaults.standard.bool(forKey: DefaultsKey.menuBarIconHidden)
        if hidden {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
                self.statusItem = nil
            }
        } else if statusItem == nil {
            statusItem = makeStatusItem()
        }
    }

    @objc private func startDictation() {
        service.start()
    }

    @objc private func stopDictation() {
        service.finish()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func toggleMenuBarIcon() {
        let hidden = UserDefaults.standard.bool(forKey: DefaultsKey.menuBarIconHidden)
        UserDefaults.standard.set(!hidden, forKey: DefaultsKey.menuBarIconHidden)
        applyMenuBarIconVisibility()
    }

    @objc private func changeShortcut() {
        if let recorder = shortcutRecorder {
            recorder.present()
            return
        }
        let current = GlobalShortcut.saved(for: DefaultsKey.speechToTextShortcut,
                                            fallback: .speechToTextDefault)
        let recorder = ShortcutRecorderWindowController(current: current)
        recorder.onRecord = { [weak self] shortcut in
            UserDefaults.standard.set(shortcut.storageValue,
                                      forKey: DefaultsKey.speechToTextShortcut)
            self?.service.syncWithPreferences()
        }
        recorder.onClose = { [weak self] in
            self?.shortcutRecorder = nil
        }
        shortcutRecorder = recorder
        recorder.present()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let shortcut = GlobalShortcut.saved(for: DefaultsKey.speechToTextShortcut,
                                            fallback: .speechToTextDefault)
        hintItem.title = "Hold \(shortcut.displayString) and speak; release to insert."
        showInMenuBarItem.state = UserDefaults.standard.bool(forKey: DefaultsKey.menuBarIconHidden) ? .off : .on
        let busy = service.state == .requestingPermission
            || service.state == .listening
            || service.state == .finishing
        startItem.isEnabled = !busy
        stopItem.isEnabled = service.state == .listening || service.state == .finishing
    }
}
