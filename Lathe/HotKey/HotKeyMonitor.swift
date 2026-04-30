import AppKit
import CoreGraphics

@MainActor
protocol HotKeyMonitorDelegate: AnyObject {
    func hotKeyDidArm()
    func hotKeyDidDisarm()
    func hotKeyDidRequestNext()
    func hotKeyDidRequestPrevious()
    func hotKeyDidCancel()
}

enum HotKeyMonitorError: Error {
    case accessibilityNotGranted
    case eventTapCreationFailed
}

@MainActor
final class HotKeyMonitor {
    weak var delegate: HotKeyMonitorDelegate?

    private var flagsTap: CFMachPort?
    private var keyTap: CFMachPort?
    private var flagsRunLoopSource: CFRunLoopSource?
    private var keyRunLoopSource: CFRunLoopSource?

    private var commandIsDown = false

    private let tabKeyCode: CGKeyCode = 0x30
    private let escKeyCode: CGKeyCode = 0x35

    func start() throws {
        guard AXIsProcessTrusted() else {
            throw HotKeyMonitorError.accessibilityNotGranted
        }
        try installFlagsTap()
        try installKeyTap()
    }

    func stop() {
        if let s = flagsRunLoopSource { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), s, .commonModes) }
        if let s = keyRunLoopSource   { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), s, .commonModes) }
        if let t = flagsTap { CGEvent.tapEnable(tap: t, enable: false) }
        if let t = keyTap   { CGEvent.tapEnable(tap: t, enable: false) }
        flagsTap = nil; keyTap = nil
        flagsRunLoopSource = nil; keyRunLoopSource = nil
    }

    private func installFlagsTap() throws {
        let mask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleFlagsNonisolated(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw HotKeyMonitorError.eventTapCreationFailed
        }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        flagsTap = tap
        flagsRunLoopSource = src
    }

    private func installKeyTap() throws {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<HotKeyMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleKeyNonisolated(type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            throw HotKeyMonitorError.eventTapCreationFailed
        }
        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        keyTap = tap
        keyRunLoopSource = src
    }

    nonisolated private func handleFlagsNonisolated(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async { [weak self] in
                guard let self, let t = self.flagsTap else { return }
                CGEvent.tapEnable(tap: t, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        let cmdDown = event.flags.contains(.maskCommand)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if cmdDown != self.commandIsDown {
                self.commandIsDown = cmdDown
                if cmdDown {
                    self.delegate?.hotKeyDidArm()
                } else {
                    self.delegate?.hotKeyDidDisarm()
                }
            }
        }
        return Unmanaged.passUnretained(event)
    }

    nonisolated private func handleKeyNonisolated(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DispatchQueue.main.async { [weak self] in
                guard let self, let t = self.keyTap else { return }
                CGEvent.tapEnable(tap: t, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        guard event.flags.contains(.maskCommand) else {
            return Unmanaged.passUnretained(event)
        }
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let shift = event.flags.contains(.maskShift)

        switch keyCode {
        case tabKeyCode:
            DispatchQueue.main.async { [weak self] in
                if shift {
                    self?.delegate?.hotKeyDidRequestPrevious()
                } else {
                    self?.delegate?.hotKeyDidRequestNext()
                }
            }
            return nil
        case escKeyCode:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidCancel()
            }
            return nil
        default:
            return Unmanaged.passUnretained(event)
        }
    }
}
