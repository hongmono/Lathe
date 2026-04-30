import Foundation
import AppKit
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Key {
        static let appearance = "appearance"
        static let layoutStyle = "layoutStyle"
        static let cardSize = "cardSize"
        static let angularStep = "angularStep"
        static let autoCheckUpdates = "autoCheckUpdates"
    }

    static let defaultCardSize: Double = 110
    static let defaultAngularStep: Double = 13

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
    }

    @Published var layoutStyle: LayoutStyle {
        didSet { UserDefaults.standard.set(layoutStyle.rawValue, forKey: Key.layoutStyle) }
    }

    @Published var cardSize: Double {
        didSet { UserDefaults.standard.set(cardSize, forKey: Key.cardSize) }
    }

    @Published var angularStep: Double {
        didSet { UserDefaults.standard.set(angularStep, forKey: Key.angularStep) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            let success = LoginItem.setEnabled(launchAtLogin)
            if !success {
                launchAtLogin = oldValue
            }
        }
    }

    @Published var autoCheckUpdates: Bool {
        didSet { UserDefaults.standard.set(autoCheckUpdates, forKey: Key.autoCheckUpdates) }
    }

    @Published var availableUpdate: UpdateInfo?
    @Published var lastUpdateCheck: Date?
    @Published var isCheckingForUpdates: Bool = false
    @Published var updateCheckError: String?

    private init() {
        let d = UserDefaults.standard
        self.appearance = Appearance(rawValue: d.string(forKey: Key.appearance) ?? "") ?? .system
        self.layoutStyle = LayoutStyle(rawValue: d.string(forKey: Key.layoutStyle) ?? "") ?? .fan
        self.cardSize = (d.object(forKey: Key.cardSize) as? Double) ?? Self.defaultCardSize
        self.angularStep = (d.object(forKey: Key.angularStep) as? Double) ?? Self.defaultAngularStep
        self.launchAtLogin = LoginItem.isEnabled
        self.autoCheckUpdates = (d.object(forKey: Key.autoCheckUpdates) as? Bool) ?? true
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }

    func resetCarouselDefaults() {
        cardSize = Self.defaultCardSize
        angularStep = Self.defaultAngularStep
    }

    func checkForUpdates() async {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        updateCheckError = nil
        defer { isCheckingForUpdates = false }

        do {
            let info = try await UpdateChecker.fetchLatestRelease()
            lastUpdateCheck = Date()
            if UpdateChecker.isNewer(latest: info.version, than: UpdateChecker.currentVersion()) {
                availableUpdate = info
            } else {
                availableUpdate = nil
            }
        } catch {
            updateCheckError = "Couldn't reach the update server."
        }
    }
}
