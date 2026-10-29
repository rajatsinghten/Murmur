// SPDX-License-Identifier: MIT

import Carbon.HIToolbox
import Foundation

/// One Carbon global hotkey with register/unregister lifecycle. A single
/// process-wide event handler routes presses to the owning instance by id.
final class QuickToolHotkey {
    private static var instances: [UInt32: QuickToolHotkey] = [:]
    private static var sharedHandler: EventHandlerRef?

    private let hotKeyID: UInt32
    private var hotKeyRef: EventHotKeyRef?
    private var registeredShortcut: GlobalShortcut?
    var onPress: (() -> Void)?
    var onRelease: (() -> Void)?

    init(id: UInt32) {
        hotKeyID = id
    }

    /// Applies the wanted state; returns false when macOS refused the
    /// registration (combination taken by another app).
    @discardableResult
    func sync(enabled: Bool, shortcut: GlobalShortcut, storageKey: String) -> Bool {
        guard enabled else {
            unregister()
            return true
        }
        if hotKeyRef != nil, registeredShortcut == shortcut {
            return true
        }
        unregister()
        Self.installSharedHandlerIfNeeded()
        Self.instances[hotKeyID] = self
        let id = EventHotKeyID(signature: 0x4D55_524D, id: hotKeyID) // 'MURM'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(shortcut.carbonKeyCode,
                                         shortcut.carbonModifiers,
                                         id, GetEventDispatcherTarget(), 0, &ref)
        guard status == noErr, let ref else {
            registeredShortcut = nil
            return false
        }
        hotKeyRef = ref
        registeredShortcut = shortcut
        return true
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRef = nil
        registeredShortcut = nil
        Self.instances.removeValue(forKey: hotKeyID)
    }

    private static func installSharedHandlerIfNeeded() {
        guard sharedHandler == nil else { return }
        var specs = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ -> OSStatus in
            var id = EventHotKeyID()
            if let event {
                GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                  EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &id)
            }
            guard id.signature == 0x4D55_524D,
                  let instance = QuickToolHotkey.instances[id.id]
            else { return OSStatus(eventNotHandledErr) }
            let kind = event.map(GetEventKind) ?? 0
            DispatchQueue.main.async {
                if kind == UInt32(kEventHotKeyPressed) {
                    instance.onPress?()
                } else if kind == UInt32(kEventHotKeyReleased) {
                    instance.onRelease?()
                }
            }
            return noErr
        }, specs.count, &specs, nil, &sharedHandler)
    }
}
