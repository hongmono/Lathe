import Foundation
import AppKit
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    static let finderBundleIdentifier = "com.apple.finder"

    private enum Key {
        static let appLanguage = AppLanguage.defaultsKey
        static let appearance = "appearance"
        static let layoutStyle = "layoutStyle"
        static let cardSize = "cardSize"
        static let angularStep = "angularStep"
        static let showAppNamesInCarousel = "showAppNamesInCarousel"
        static let autoCheckUpdates = "autoCheckUpdates"
        static let hiddenAppBundleIdentifiers = "hiddenAppBundleIdentifiers"
        static let excludedBundleIdentifiers = "excludedBundleIdentifiers"
        static let finderHiddenAppSeeded = "finderHiddenAppSeeded"
    }

    static let defaultCardSize: Double = 110
    static let defaultAngularStep: Double = 13

    private let defaults: UserDefaults

    @Published var appLanguage: AppLanguage {
        didSet { defaults.set(appLanguage.rawValue, forKey: Key.appLanguage) }
    }

    @Published var appearance: Appearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
    }

    @Published var layoutStyle: LayoutStyle {
        didSet { defaults.set(layoutStyle.rawValue, forKey: Key.layoutStyle) }
    }

    @Published var cardSize: Double {
        didSet { defaults.set(cardSize, forKey: Key.cardSize) }
    }

    @Published var angularStep: Double {
        didSet { defaults.set(angularStep, forKey: Key.angularStep) }
    }

    @Published var showAppNamesInCarousel: Bool {
        didSet { defaults.set(showAppNamesInCarousel, forKey: Key.showAppNamesInCarousel) }
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
        didSet { defaults.set(autoCheckUpdates, forKey: Key.autoCheckUpdates) }
    }

    @Published var excludedBundleIdentifiers: Set<String> {
        didSet {
            defaults.set(excludedBundleIdentifiers.sorted(), forKey: Key.excludedBundleIdentifiers)
        }
    }

    @Published var hiddenAppBundleIdentifiers: Set<String> {
        didSet {
            defaults.set(hiddenAppBundleIdentifiers.sorted(), forKey: Key.hiddenAppBundleIdentifiers)
        }
    }

    @Published var availableUpdate: UpdateInfo?
    @Published var lastUpdateCheck: Date?
    @Published var isCheckingForUpdates: Bool = false
    @Published var updateCheckError: String?

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        self.appLanguage = AppLanguage(rawValue: userDefaults.string(forKey: Key.appLanguage) ?? "") ?? .system
        self.appearance = Appearance(rawValue: userDefaults.string(forKey: Key.appearance) ?? "") ?? .system
        self.layoutStyle = LayoutStyle(rawValue: userDefaults.string(forKey: Key.layoutStyle) ?? "") ?? .fan
        self.cardSize = (userDefaults.object(forKey: Key.cardSize) as? Double) ?? Self.defaultCardSize
        self.angularStep = (userDefaults.object(forKey: Key.angularStep) as? Double) ?? Self.defaultAngularStep
        self.showAppNamesInCarousel = (userDefaults.object(forKey: Key.showAppNamesInCarousel) as? Bool) ?? true
        self.launchAtLogin = LoginItem.isEnabled
        self.autoCheckUpdates = (userDefaults.object(forKey: Key.autoCheckUpdates) as? Bool) ?? true
        var excludedBundleIdentifiers = Set(userDefaults.stringArray(forKey: Key.excludedBundleIdentifiers) ?? [])
        self.excludedBundleIdentifiers = excludedBundleIdentifiers
        let hasHiddenAppBundleIdentifiers = userDefaults.object(forKey: Key.hiddenAppBundleIdentifiers) != nil
        let hasSeededFinderHiddenApp = userDefaults.bool(forKey: Key.finderHiddenAppSeeded)
        var shouldPersistHiddenAppBundleIdentifiers = !hasHiddenAppBundleIdentifiers
        var shouldPersistExcludedBundleIdentifiers = false
        if let hiddenAppBundleIdentifiers = userDefaults.stringArray(forKey: Key.hiddenAppBundleIdentifiers) {
            self.hiddenAppBundleIdentifiers = Set(hiddenAppBundleIdentifiers)
        } else {
            self.hiddenAppBundleIdentifiers = excludedBundleIdentifiers
        }

        if !hasSeededFinderHiddenApp {
            self.hiddenAppBundleIdentifiers.insert(Self.finderBundleIdentifier)
            excludedBundleIdentifiers.insert(Self.finderBundleIdentifier)
            self.excludedBundleIdentifiers = excludedBundleIdentifiers
            shouldPersistHiddenAppBundleIdentifiers = true
            shouldPersistExcludedBundleIdentifiers = true
            defaults.set(true, forKey: Key.finderHiddenAppSeeded)
        }

        if shouldPersistHiddenAppBundleIdentifiers {
            defaults.set(self.hiddenAppBundleIdentifiers.sorted(), forKey: Key.hiddenAppBundleIdentifiers)
        }
        if shouldPersistExcludedBundleIdentifiers {
            defaults.set(self.excludedBundleIdentifiers.sorted(), forKey: Key.excludedBundleIdentifiers)
        }
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }

    func resetCarouselDefaults() {
        cardSize = Self.defaultCardSize
        angularStep = Self.defaultAngularStep
        showAppNamesInCarousel = true
    }

    func isExcluded(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else { return false }
        return excludedBundleIdentifiers.contains(bundleIdentifier)
    }

    func setExcluded(_ excluded: Bool, bundleIdentifier: String) {
        if excluded {
            hiddenAppBundleIdentifiers.insert(bundleIdentifier)
            excludedBundleIdentifiers.insert(bundleIdentifier)
        } else {
            excludedBundleIdentifiers.remove(bundleIdentifier)
        }
    }

    func addHiddenApp(bundleIdentifier: String) {
        hiddenAppBundleIdentifiers.insert(bundleIdentifier)
        excludedBundleIdentifiers.insert(bundleIdentifier)
    }

    func removeHiddenApps(bundleIdentifiers: Set<String>) {
        hiddenAppBundleIdentifiers.subtract(bundleIdentifiers)
        excludedBundleIdentifiers.subtract(bundleIdentifiers)
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
            updateCheckError = L10n.string("settings.about.updateError")
        }
    }
}
