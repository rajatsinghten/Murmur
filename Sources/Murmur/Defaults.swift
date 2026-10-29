// SPDX-License-Identifier: GPL-3.0-or-later

import Foundation

enum DefaultsKey {
    static let speechToTextShortcutEnabled = "speechToTextShortcutEnabled"
    static let speechToTextShortcut = "speechToTextShortcut"
    static let menuBarIconHidden = "menuBarIconHidden"
}

enum Defaults {
    static func register() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.speechToTextShortcutEnabled: true,
            DefaultsKey.speechToTextShortcut: GlobalShortcut.speechToTextDefault.storageValue,
            DefaultsKey.menuBarIconHidden: false,
        ])
    }
}
