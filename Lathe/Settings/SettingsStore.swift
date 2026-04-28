import Foundation
import AppKit
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private enum Key {
        static let appearance = "appearance"
        static let cardSize = "cardSize"
        static let angularStep = "angularStep"
    }

    static let defaultCardSize: Double = 110
    static let defaultAngularStep: Double = 13

    @Published var appearance: Appearance {
        didSet {
            UserDefaults.standard.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
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

    private init() {
        let d = UserDefaults.standard
        self.appearance = Appearance(rawValue: d.string(forKey: Key.appearance) ?? "") ?? .system
        self.cardSize = (d.object(forKey: Key.cardSize) as? Double) ?? Self.defaultCardSize
        self.angularStep = (d.object(forKey: Key.angularStep) as? Double) ?? Self.defaultAngularStep
        self.launchAtLogin = LoginItem.isEnabled
    }

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }

    func resetCarouselDefaults() {
        cardSize = Self.defaultCardSize
        angularStep = Self.defaultAngularStep
    }
}
