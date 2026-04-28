import Foundation
import AppKit
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Key {
        static let appearance = "appearance"
        static let cardWidth = "cardWidth"
        static let cardHeight = "cardHeight"
        static let pivotDistance = "pivotDistance"
        static let angularStep = "angularStep"
    }

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
    }

    @Published var cardWidth: Double {
        didSet { UserDefaults.standard.set(cardWidth, forKey: Key.cardWidth) }
    }

    @Published var cardHeight: Double {
        didSet { UserDefaults.standard.set(cardHeight, forKey: Key.cardHeight) }
    }

    @Published var pivotDistance: Double {
        didSet { UserDefaults.standard.set(pivotDistance, forKey: Key.pivotDistance) }
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

    private init() {
        let d = UserDefaults.standard
        self.appearance = Appearance(rawValue: d.string(forKey: Key.appearance) ?? "") ?? .system
        self.cardWidth = (d.object(forKey: Key.cardWidth) as? Double) ?? 110
        self.cardHeight = (d.object(forKey: Key.cardHeight) as? Double) ?? 150
        self.pivotDistance = (d.object(forKey: Key.pivotDistance) as? Double) ?? 320
        self.angularStep = (d.object(forKey: Key.angularStep) as? Double) ?? 13
        self.launchAtLogin = LoginItem.isEnabled
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }

    func resetCarouselDefaults() {
        cardWidth = 110
        cardHeight = 150
        pivotDistance = 320
        angularStep = 13
    }
}
