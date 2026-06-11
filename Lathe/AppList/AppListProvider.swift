import AppKit
import Combine

@MainActor
final class AppListProvider {
    private(set) var apps: [AppEntry] = []
    var didChange: () -> Void = {}

    private let settings: SettingsStore
    private let currentSpaceWindowProvider: any CurrentSpaceWindowProviding
    private var appOrder = SpaceScopedAppOrder()
    private var observers: [NSObjectProtocol] = []
    private var cancellables = Set<AnyCancellable>()

    init(settings: SettingsStore = .shared,
         currentSpaceWindowProvider: any CurrentSpaceWindowProviding = CurrentSpaceWindowProvider()) {
        self.settings = settings
        self.currentSpaceWindowProvider = currentSpaceWindowProvider
        rebuildSnapshot()
        registerObservers()
        observeSettings()
    }

    func refresh() {
        rebuildSnapshot()
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
        observers.append(nc.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
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
        let currentSpaceProcessIdentifiers = currentSpaceWindowProvider.processIdentifiers()
        appOrder.touch(pid: pid, currentSpaceProcessIdentifiers: currentSpaceProcessIdentifiers)
        rebuildSnapshot(currentSpaceProcessIdentifiers: currentSpaceProcessIdentifiers)
    }

    private func rebuildSnapshot(currentSpaceProcessIdentifiers: Set<pid_t>? = nil) {
        let running = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }

        appOrder.reconcileLiveProcessIdentifiers(running.map(\.processIdentifier))

        let byPid: [pid_t: NSRunningApplication] = Dictionary(
            uniqueKeysWithValues: running.map { ($0.processIdentifier, $0) }
        )

        let currentSpaceProcessIdentifiers = currentSpaceProcessIdentifiers ?? currentSpaceWindowProvider.processIdentifiers()
        let entries = appOrder.orderedProcessIdentifiers(
            currentSpaceProcessIdentifiers: currentSpaceProcessIdentifiers
        ).compactMap { pid -> AppEntry? in
            guard let app = byPid[pid] else { return nil }
            let icon = app.icon ?? NSImage()
            let name = app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown")
            return AppEntry(
                id: pid,
                bundleIdentifier: app.bundleIdentifier,
                name: name,
                icon: icon,
                isCurrentSpace: currentSpaceProcessIdentifiers.contains(pid)
            )
        }
        let visibleEntries = AppEntry.visibleInCarousel(
            entries,
            excludingBundleIdentifiers: settings.excludedBundleIdentifiers
        )
        apps = visibleEntries
        didChange()
    }
}
