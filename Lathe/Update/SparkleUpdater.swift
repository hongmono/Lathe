import Combine
import Foundation
import Sparkle

@MainActor
final class SparkleUpdater: ObservableObject {
    static let shared = SparkleUpdater()

    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecksForUpdates = false

    private let updaterController: SPUStandardUpdaterController
    private var cancellables = Set<AnyCancellable>()

    private init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: !Self.isRunningTests,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        canCheckForUpdates = updaterController.updater.canCheckForUpdates
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates

        updaterController.updater.publisher(for: \.canCheckForUpdates, options: [.initial, .new])
            .sink { [weak self] canCheckForUpdates in
                self?.canCheckForUpdates = canCheckForUpdates
            }
            .store(in: &cancellables)

        updaterController.updater.publisher(for: \.automaticallyChecksForUpdates, options: [.initial, .new])
            .sink { [weak self] automaticallyChecksForUpdates in
                self?.automaticallyChecksForUpdates = automaticallyChecksForUpdates
            }
            .store(in: &cancellables)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
    }

    static func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
