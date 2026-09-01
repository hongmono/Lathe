import AppKit

protocol SwitcherRunningApplication: AnyObject {
    var bundleIdentifier: String? { get }
    var isHidden: Bool { get }

    @discardableResult
    func hide() -> Bool

    @discardableResult
    func unhide() -> Bool

    @discardableResult
    func terminate() -> Bool
}

extension NSRunningApplication: SwitcherRunningApplication {}

enum AppSwitcherApplicationController {
    static let finderBundleIdentifier = "com.apple.finder"

    @discardableResult
    static func toggleHidden(_ application: any SwitcherRunningApplication) -> Bool {
        application.isHidden ? application.unhide() : application.hide()
    }

    @discardableResult
    static func requestTermination(_ application: any SwitcherRunningApplication) -> Bool {
        guard application.bundleIdentifier != finderBundleIdentifier else { return false }
        return application.terminate()
    }
}
