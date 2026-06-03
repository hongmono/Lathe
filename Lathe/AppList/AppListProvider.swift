import AppKit
import Combine

@MainActor
final class AppListProvider {
    private(set) var apps: [AppEntry] = []
    var didChange: () -> Void = {}

    private let settings: SettingsStore
    private var mruOrder: [pid_t] = []
    private var observers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore = .shared) {
        self.settings = settings
        rebuildSnapshot()
        registerObservers()
        observeSettings()
    }

    private func registerObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        observers.append(nc.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self else { return }
            if let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                MainActor.assumeIsolated {
                    self.touch(pid: app.processIdentifier)
                }
            }
        })
        observers.append(nc.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rebuildSnapshot()
            }
        })
        observers.append(nc.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rebuildSnapshot()
            }
        })
    }

    private func observeSettings() {
        settings.$excludedBundleIdentifiers
            .dropFirst()
            .sink { [weak self] _ in
                self?.rebuildSnapshot()
            }
            .store(in: &cancellables)
    }

    private func touch(pid: pid_t) {
        mruOrder.removeAll { $0 == pid }
        mruOrder.insert(pid, at: 0)
        rebuildSnapshot()
    }

    private func rebuildSnapshot() {
        let running = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }

        let known = Set(mruOrder)
        for app in running where !known.contains(app.processIdentifier) {
            mruOrder.append(app.processIdentifier)
        }
        let livePids = Set(running.map(\.processIdentifier))
        mruOrder.removeAll { !livePids.contains($0) }

        let byPid: [pid_t: NSRunningApplication] = Dictionary(
            uniqueKeysWithValues: running.map { ($0.processIdentifier, $0) }
        )

        let entries = mruOrder.compactMap { pid -> AppEntry? in
            guard let app = byPid[pid] else { return nil }
            let icon = app.icon ?? NSImage()
            let name = app.localizedName ?? app.bundleIdentifier ?? "Unknown"
            return AppEntry(
                id: pid,
                bundleIdentifier: app.bundleIdentifier,
                name: name,
                icon: icon
            )
        }
        apps = AppEntry.visibleInCarousel(
            entries,
            excludingBundleIdentifiers: settings.excludedBundleIdentifiers
        )
        didChange()
    }
}
