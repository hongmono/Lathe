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
        static let layoutMode = "layoutMode"
        static let cardSize = "cardSize"
        static let angularStep = "angularStep"
        static let fanRadius = "fanRadius"
        static let fanSpacing = "fanSpacing"
        static let showAppNamesInCarousel = "showAppNamesInCarousel"
        static let animateCarouselPresentation = "animateCarouselPresentation"
        static let windowListAnimationStyle = "windowListAnimationStyle"
        static let windowListAnimationSpeed = "windowListAnimationSpeed"
        static let windowListAnimationDelay = "windowListAnimationDelay"
        static let showBrowserTabsInCarousel = "showBrowserTabsInCarousel"
        static let reopenWindowlessApplications = "reopenWindowlessApplications"
        static let hiddenAppBundleIdentifiers = "hiddenAppBundleIdentifiers"
        static let excludedBundleIdentifiers = "excludedBundleIdentifiers"
        static let finderHiddenAppSeeded = "finderHiddenAppSeeded"
    }

    static let defaultCardSize: Double = 110
    static let defaultAngularStep: Double = 13
    static let defaultFanRadius: Double = CarouselGeometry.defaultFanRadius
    static let defaultFanSpacing: Double = CarouselGeometry.defaultFanSpacing
    static let defaultWindowListAnimationSpeed = 1.0
    static let windowListAnimationSpeedRange = 0.5...2.0
    static let defaultWindowListAnimationDelay = 0.3
    static let windowListAnimationDelayRange = 0.0...1.0

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

    @Published var layoutMode: LayoutMode {
        didSet { defaults.set(layoutMode.rawValue, forKey: Key.layoutMode) }
    }

    @Published var cardSize: Double {
        didSet { defaults.set(cardSize, forKey: Key.cardSize) }
    }

    @Published var angularStep: Double {
        didSet { defaults.set(angularStep, forKey: Key.angularStep) }
    }

    @Published var fanRadius: Double {
        didSet { defaults.set(CarouselGeometry.clampedFanRadius(fanRadius), forKey: Key.fanRadius) }
    }

    @Published var fanSpacing: Double {
        didSet { defaults.set(CarouselGeometry.clampedFanSpacing(fanSpacing), forKey: Key.fanSpacing) }
    }

    @Published var showAppNamesInCarousel: Bool {
        didSet { defaults.set(showAppNamesInCarousel, forKey: Key.showAppNamesInCarousel) }
    }

    @Published var animateCarouselPresentation: Bool {
        didSet { defaults.set(animateCarouselPresentation, forKey: Key.animateCarouselPresentation) }
    }

    @Published var windowListAnimationStyle: WindowListAnimationStyle {
        didSet { defaults.set(windowListAnimationStyle.rawValue, forKey: Key.windowListAnimationStyle) }
    }

    @Published var windowListAnimationSpeed: Double {
        didSet {
            defaults.set(
                Self.clampedWindowListAnimationSpeed(windowListAnimationSpeed),
                forKey: Key.windowListAnimationSpeed
            )
        }
    }

    @Published var windowListAnimationDelay: Double {
        didSet {
            defaults.set(
                Self.clampedWindowListAnimationDelay(windowListAnimationDelay),
                forKey: Key.windowListAnimationDelay
            )
        }
    }

    @Published var showBrowserTabsInCarousel: Bool {
        didSet { defaults.set(showBrowserTabsInCarousel, forKey: Key.showBrowserTabsInCarousel) }
    }

    @Published var reopenWindowlessApplications: Bool {
        didSet { defaults.set(reopenWindowlessApplications, forKey: Key.reopenWindowlessApplications) }
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

    init(userDefaults: UserDefaults = .standard) {
        self.defaults = userDefaults
        self.appLanguage = AppLanguage(rawValue: userDefaults.string(forKey: Key.appLanguage) ?? "") ?? .system
        self.appearance = Appearance(rawValue: userDefaults.string(forKey: Key.appearance) ?? "") ?? .system
        self.layoutStyle = LayoutStyle(rawValue: userDefaults.string(forKey: Key.layoutStyle) ?? "") ?? .fan
        self.layoutMode = LayoutMode(rawValue: userDefaults.string(forKey: Key.layoutMode) ?? "") ?? .carousel
        self.cardSize = (userDefaults.object(forKey: Key.cardSize) as? Double) ?? Self.defaultCardSize
        self.angularStep = (userDefaults.object(forKey: Key.angularStep) as? Double) ?? Self.defaultAngularStep
        self.fanRadius = CarouselGeometry.storedFanRadius(userDefaults.object(forKey: Key.fanRadius) as? Double)
        self.fanSpacing = CarouselGeometry.storedFanSpacing(userDefaults.object(forKey: Key.fanSpacing) as? Double)
        self.showAppNamesInCarousel = (userDefaults.object(forKey: Key.showAppNamesInCarousel) as? Bool) ?? true
        self.animateCarouselPresentation =
            (userDefaults.object(forKey: Key.animateCarouselPresentation) as? Bool) ?? true
        self.windowListAnimationStyle = WindowListAnimationStyle(
            rawValue: userDefaults.string(forKey: Key.windowListAnimationStyle) ?? ""
        ) ?? .staggered
        self.windowListAnimationSpeed = Self.clampedWindowListAnimationSpeed(
            (userDefaults.object(forKey: Key.windowListAnimationSpeed) as? Double)
                ?? Self.defaultWindowListAnimationSpeed
        )
        self.windowListAnimationDelay = Self.clampedWindowListAnimationDelay(
            (userDefaults.object(forKey: Key.windowListAnimationDelay) as? Double)
                ?? Self.defaultWindowListAnimationDelay
        )
        self.showBrowserTabsInCarousel =
            (userDefaults.object(forKey: Key.showBrowserTabsInCarousel) as? Bool) ?? false
        self.reopenWindowlessApplications =
            (userDefaults.object(forKey: Key.reopenWindowlessApplications) as? Bool) ?? true
        self.launchAtLogin = LoginItem.isEnabled
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
        fanRadius = Self.defaultFanRadius
        fanSpacing = Self.defaultFanSpacing
        showAppNamesInCarousel = true
        showBrowserTabsInCarousel = false
    }

    func resetAnimationDefaults() {
        animateCarouselPresentation = true
        windowListAnimationStyle = .staggered
        windowListAnimationSpeed = Self.defaultWindowListAnimationSpeed
        windowListAnimationDelay = Self.defaultWindowListAnimationDelay
    }

    static func clampedWindowListAnimationSpeed(_ speed: Double) -> Double {
        min(max(speed, windowListAnimationSpeedRange.lowerBound), windowListAnimationSpeedRange.upperBound)
    }

    static func clampedWindowListAnimationDelay(_ delay: Double) -> Double {
        min(max(delay, windowListAnimationDelayRange.lowerBound), windowListAnimationDelayRange.upperBound)
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
}
