import SwiftUI
import AppKit

struct HiddenAppsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var hiddenAppRows: [HiddenAppRowModel] = []
    @State private var selectedHiddenAppBundleIdentifiers: Set<String> = []

    var body: some View {
        hiddenAppsList
            .frame(maxWidth: .infinity, alignment: .leading)
            .onAppear {
                refreshAppExclusionOptions()
            }
            .onReceive(store.$excludedBundleIdentifiers) { _ in
                refreshAppExclusionOptions()
            }
            .onReceive(store.$hiddenAppBundleIdentifiers) { _ in
                refreshAppExclusionOptions()
            }
    }

    private var hiddenAppsList: some View {
        VStack(spacing: 0) {
            hiddenAppsHeader

            Divider()

            ZStack(alignment: .topLeading) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(hiddenAppRows) { row in
                            HiddenAppRowView(
                                row: row,
                                isSelected: selectedHiddenAppBundleIdentifiers.contains(row.bundleIdentifier),
                                isHidden: excludedBinding(for: row.bundleIdentifier)
                            ) {
                                toggleSelection(for: row.bundleIdentifier)
                            }

                            Divider()
                                .padding(.leading, HiddenAppsListLayout.rowHorizontalPadding)
                        }
                    }
                }

                if hiddenAppRows.isEmpty {
                    Text(L10n.string("settings.hiddenApps.empty"))
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(HiddenAppsListLayout.rowHorizontalPadding)
                }
            }
            .frame(height: HiddenAppsListLayout.listHeight)

            Divider()

            hiddenAppsControlBar
        }
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary, lineWidth: 0.5)
        }
    }

    private var hiddenAppsHeader: some View {
        HStack(spacing: 12) {
            Text(L10n.string("settings.hiddenApps.app"))
                .frame(width: HiddenAppsListLayout.appColumnWidth, alignment: .leading)

            Text(L10n.string("settings.hiddenApps.bundleIdentifier"))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(L10n.string("settings.hiddenApps.hidden"))
                .frame(width: HiddenAppsListLayout.toggleColumnWidth, alignment: .trailing)
        }
        .font(.system(size: 13, weight: .semibold))
        .padding(.horizontal, HiddenAppsListLayout.rowHorizontalPadding)
        .frame(height: HiddenAppsListLayout.headerHeight)
        .background(.ultraThinMaterial)
    }

    private var hiddenAppsControlBar: some View {
        HStack(spacing: 0) {
            Button {
                addHiddenApp()
            } label: {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(L10n.string("settings.hiddenApps.add"))
            .accessibilityLabel(L10n.string("settings.hiddenApps.add"))

            Divider()
                .frame(height: 16)

            Button {
                removeSelectedHiddenApps()
            } label: {
                Image(systemName: "minus")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .disabled(selectedHiddenAppBundleIdentifiers.isEmpty)
            .help(L10n.string("settings.hiddenApps.remove"))
            .accessibilityLabel(L10n.string("settings.hiddenApps.remove"))

            Spacer()
        }
        .frame(height: 26)
        .padding(.horizontal, 6)
        .background(.thinMaterial)
    }

    private func toggleSelection(for bundleIdentifier: String) {
        if selectedHiddenAppBundleIdentifiers.contains(bundleIdentifier) {
            selectedHiddenAppBundleIdentifiers.remove(bundleIdentifier)
        } else {
            selectedHiddenAppBundleIdentifiers.insert(bundleIdentifier)
        }
    }

    private func excludedBinding(for bundleIdentifier: String) -> Binding<Bool> {
        Binding {
            store.isExcluded(bundleIdentifier: bundleIdentifier)
        } set: { excluded in
            store.setExcluded(excluded, bundleIdentifier: bundleIdentifier)
        }
    }

    private func addHiddenApp() {
        let panel = ApplicationOpenPanel.make(title: L10n.string("settings.hiddenApps.add"))

        guard panel.runModal() == .OK,
              let url = panel.url,
              let metadata = AppBundleMetadata.metadata(applicationURL: url) else {
            return
        }

        store.addHiddenApp(bundleIdentifier: metadata.bundleIdentifier)
        selectedHiddenAppBundleIdentifiers = [metadata.bundleIdentifier]
        refreshAppExclusionOptions()
    }

    private func removeSelectedHiddenApps() {
        guard !selectedHiddenAppBundleIdentifiers.isEmpty else { return }

        store.removeHiddenApps(bundleIdentifiers: selectedHiddenAppBundleIdentifiers)
        selectedHiddenAppBundleIdentifiers.removeAll()
        refreshAppExclusionOptions()
    }

    private func refreshAppExclusionOptions() {
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .map { app in
                AppEntry(
                    id: app.processIdentifier,
                    bundleIdentifier: app.bundleIdentifier,
                    name: app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown"),
                    icon: app.icon ?? NSImage()
                )
            }
        let listedBundleIdentifiers = store.hiddenAppBundleIdentifiers
        let installedApps = listedBundleIdentifiers.compactMap {
            AppBundleMetadata.resolve(bundleIdentifier: $0)
        }
        let options = AppExclusionOption.options(
            from: apps,
            excludedBundleIdentifiers: listedBundleIdentifiers,
            installedApps: installedApps
        )
        hiddenAppRows = HiddenAppRowModel.rows(
            from: options,
            excludedBundleIdentifiers: store.excludedBundleIdentifiers
        )
        let currentBundleIdentifiers = Set(hiddenAppRows.map(\.bundleIdentifier))
        selectedHiddenAppBundleIdentifiers.formIntersection(currentBundleIdentifiers)
    }
}

private enum HiddenAppsListLayout {
    static let appColumnWidth: CGFloat = 150
    static let toggleColumnWidth: CGFloat = 58
    static let headerHeight: CGFloat = 32
    static let listHeight: CGFloat = 360
    static let rowHeight: CGFloat = 44
    static let rowHorizontalPadding: CGFloat = 16
}

private struct HiddenAppRowView: View {
    let row: HiddenAppRowModel
    let isSelected: Bool
    @Binding var isHidden: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                if let icon = row.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 22, height: 22)
                }

                Text(row.name)
                    .lineLimit(1)
            }
            .frame(width: HiddenAppsListLayout.appColumnWidth, alignment: .leading)

            Text(row.bundleIdentifier)
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Toggle(L10n.string("settings.hiddenApps.hidden"), isOn: $isHidden)
                .labelsHidden()
                .toggleStyle(.switch)
                .frame(width: HiddenAppsListLayout.toggleColumnWidth, alignment: .trailing)
                .help(L10n.string("settings.hiddenApps.hidden"))
                .accessibilityLabel(L10n.string("settings.hiddenApps.hidden"))
                .accessibilityIdentifier("hidden-app-toggle-\(row.bundleIdentifier)")
        }
        .padding(.horizontal, HiddenAppsListLayout.rowHorizontalPadding)
        .frame(height: HiddenAppsListLayout.rowHeight)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? Color.accentColor.opacity(0.9) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
