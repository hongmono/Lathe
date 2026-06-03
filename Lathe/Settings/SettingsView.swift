import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var appExclusionOptions: [AppExclusionOption] = []

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $store.appearance) {
                    ForEach(Appearance.allCases) { a in
                        Text(a.label).tag(a)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Carousel") {
                Picker("Layout", selection: $store.layoutStyle) {
                    ForEach(LayoutStyle.allCases) { style in
                        Text(style.label).tag(style)
                    }
                }
                .pickerStyle(.segmented)

                slider(label: "Card size",
                       value: $store.cardSize,
                       range: 80...180,
                       suffix: "pt")
                slider(label: "Spacing",
                       value: $store.angularStep,
                       range: 6...28,
                       suffix: "°")
                Toggle("Show app names", isOn: $store.showAppNamesInCarousel)

                HStack {
                    Spacer()
                    Button("Restore defaults") {
                        store.resetCarouselDefaults()
                    }
                }
            }

            Section("Hidden Apps") {
                if appExclusionOptions.isEmpty {
                    Text("No regular apps are running.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appExclusionOptions) { option in
                        Toggle(isOn: excludedBinding(for: option.bundleIdentifier)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.name)
                                Text(option.bundleIdentifier)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Refresh") {
                        refreshAppExclusionOptions()
                    }
                }
            }

            Section("General") {
                Toggle("Launch Lathe at login", isOn: $store.launchAtLogin)
                Text("Lathe will start automatically when you sign in. You can revoke this from System Settings → General → Login Items.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(UpdateChecker.currentVersion())
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Toggle("Automatically check for updates", isOn: $store.autoCheckUpdates)

                HStack {
                    updateStatusView
                    Spacer()
                    if let update = store.availableUpdate {
                        Button("Download \(update.tagName)") {
                            NSWorkspace.shared.open(update.htmlURL)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            Task { await store.checkForUpdates() }
                        } label: {
                            if store.isCheckingForUpdates {
                                ProgressView().controlSize(.small)
                            } else {
                                Text("Check Now")
                            }
                        }
                        .disabled(store.isCheckingForUpdates)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 680)
        .onAppear {
            refreshAppExclusionOptions()
        }
        .onReceive(store.$excludedBundleIdentifiers) { _ in
            refreshAppExclusionOptions()
        }
    }

    @ViewBuilder
    private var updateStatusView: some View {
        if let err = store.updateCheckError {
            Text(err)
                .font(.system(size: 11))
                .foregroundStyle(.red)
        } else if store.availableUpdate != nil {
            Text("A new version is available.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else if let last = store.lastUpdateCheck {
            Text("Up to date · checked \(last.formatted(.relative(presentation: .named)))")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        } else {
            Text("Lathe checks GitHub Releases for new versions.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private func slider(label: String,
                        value: Binding<Double>,
                        range: ClosedRange<Double>,
                        suffix: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 96, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }

    private func excludedBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding {
            store.isExcluded(bundleIdentifier: bundleIdentifier)
        } set: { excluded in
            store.setExcluded(excluded, bundleIdentifier: bundleIdentifier)
        }
    }

    private func refreshAppExclusionOptions() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .map { app in
                AppEntry(
                    id: app.processIdentifier,
                    bundleIdentifier: app.bundleIdentifier,
                    name: app.localizedName ?? app.bundleIdentifier ?? "Unknown",
                    icon: app.icon ?? NSImage()
                )
            }
        appExclusionOptions = AppExclusionOption.options(
            from: apps,
            excludedBundleIdentifiers: store.excludedBundleIdentifiers
        )
    }
}
