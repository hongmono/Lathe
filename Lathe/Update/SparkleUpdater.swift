import AppKit
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
        // 이 앱은 .accessory(메뉴바 전용)라 평소 활성화돼 있지 않다. 먼저 앱을
        // front로 올려야 Sparkle의 "최신 버전입니다"/업데이트 알림 창이 다른 창
        // 뒤에 숨지 않고 사용자에게 보인다.
        NSApp.activate(ignoringOtherApps: true)
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
