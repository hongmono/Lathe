import AppKit
import CoreGraphics

@MainActor
protocol HotKeyMonitorDelegate: AnyObject {
    func hotKeyDidArm()
    func hotKeyDidDisarm()
    func hotKeyDidRequestNext()
    func hotKeyDidRequestPrevious()
    func hotKeyDidRequestCycleWindow()
    func hotKeyDidRequestCycleWindowPrevious()
    func hotKeyDidRequestToggleSelectedApplicationHidden()
    func hotKeyDidRequestQuitSelectedApplication()
    func hotKeyDidRequestOpenSettings()
    func hotKeyDidCancel()
}

enum HotKeyMonitorError: Error {
    case accessibilityNotGranted
    case eventTapCreationFailed
}

enum HotKeyAction: Equatable {
    case next
    case previous
    case cycleWindow
    case cycleWindowPrevious
    case toggleSelectedApplicationHidden
    case quitSelectedApplication
    case openSettings
    case cancel

    var acceptsAutoRepeat: Bool {
        switch self {
        case .next, .previous, .cycleWindow, .cycleWindowPrevious:
            true
        case .toggleSelectedApplicationHidden, .quitSelectedApplication, .openSettings, .cancel:
            false
        }
    }

    private static let tabKeyCode: CGKeyCode = 0x30
    private static let escKeyCode: CGKeyCode = 0x35
    private static let leftArrowKeyCode: CGKeyCode = 0x7B
    private static let rightArrowKeyCode: CGKeyCode = 0x7C
    private static let graveKeyCode: CGKeyCode = 0x32
    private static let sectionKeyCode: CGKeyCode = 0x0A
    private static let commaKeyCode: CGKeyCode = 0x2B
    private static let periodKeyCode: CGKeyCode = 0x2F
    private static let hKeyCode: CGKeyCode = 0x04
    private static let qKeyCode: CGKeyCode = 0x0C

    static func resolve(keyCode: CGKeyCode,
                        commandDown: Bool,
                        shiftDown: Bool,
                        overlayActionsEnabled: Bool,
                        windowCycleEnabled: Bool) -> HotKeyAction? {
        switch keyCode {
        case leftArrowKeyCode where overlayActionsEnabled:
            return .previous
        case rightArrowKeyCode where overlayActionsEnabled:
            return .next
        case tabKeyCode where commandDown:
            return shiftDown ? .previous : .next
        case graveKeyCode where commandDown && windowCycleEnabled,
             sectionKeyCode where commandDown && windowCycleEnabled:
            return shiftDown ? .cycleWindowPrevious : .cycleWindow
        case hKeyCode where commandDown && !shiftDown && overlayActionsEnabled:
            return .toggleSelectedApplicationHidden
        case qKeyCode where commandDown && !shiftDown && overlayActionsEnabled:
            return .quitSelectedApplication
        case commaKeyCode where commandDown && !shiftDown && overlayActionsEnabled:
            return .openSettings
        case periodKeyCode where commandDown && !shiftDown && overlayActionsEnabled:
            return .cancel
        case escKeyCode where commandDown:
            return .cancel
        default:
            return nil
        }
    }
}

@MainActor
final class HotKeyMonitor {
    weak var delegate: HotKeyMonitorDelegate?
    nonisolated(unsafe) var overlayActionsEnabled = false
    nonisolated(unsafe) var windowCycleEnabled = false

    private var flagsTap: CFMachPort?
    private var keyTap: CFMachPort?
    private var flagsRunLoopSource: CFRunLoopSource?
    private var keyRunLoopSource: CFRunLoopSource?

    private var commandIsDown = false

    var isRunning: Bool { keyTap != nil && flagsTap != nil }

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
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let commandDown = event.flags.contains(.maskCommand)
        let shift = event.flags.contains(.maskShift)

        guard let action = HotKeyAction.resolve(
            keyCode: keyCode,
            commandDown: commandDown,
            shiftDown: shift,
            overlayActionsEnabled: overlayActionsEnabled,
            windowCycleEnabled: windowCycleEnabled
        ) else {
            return Unmanaged.passUnretained(event)
        }

        let isAutoRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        if isAutoRepeat && !action.acceptsAutoRepeat {
            // 관리/취소 명령은 키를 길게 눌러도 한 번만 실행하되 이벤트는 원래 앱으로 흘리지 않는다.
            return nil
        }

        switch action {
        case .next:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestNext()
            }
            return nil
        case .previous:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestPrevious()
            }
            return nil
        case .cycleWindow:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestCycleWindow()
            }
            return nil
        case .cycleWindowPrevious:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestCycleWindowPrevious()
            }
            return nil
        case .toggleSelectedApplicationHidden:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestToggleSelectedApplicationHidden()
            }
            return nil
        case .quitSelectedApplication:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestQuitSelectedApplication()
            }
            return nil
        case .openSettings:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidRequestOpenSettings()
            }
            return nil
        case .cancel:
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.hotKeyDidCancel()
            }
            return nil
        }
    }
}
