import SwiftUI
import AppKit

struct HiddenAppsSettingsView: View {
    @ObservedObject var store: SettingsStore
    @State private var hiddenAppRows: [HiddenAppRowModel] = []
    @State private var selectedHiddenAppBundleIdentifiers: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: HiddenAppsListLayout.descriptionSpacing) {
            Text(L10n.string("settings.hiddenApps.description", language: store.appLanguage))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            hiddenAppsList
        }
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
            .onReceive(store.$appLanguage) { _ in
                refreshAppExclusionOptions()
            }
    }

    private var hiddenAppsList: some View {
        VStack(spacing: 0) {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(hiddenAppRows.enumerated()), id: \.element.id) { index, row in
                            HiddenAppRow(
                                row: row,
                                isSelected: selectedHiddenAppBundleIdentifiers.contains(row.bundleIdentifier),
                                isHidden: excludedBinding(for: row.bundleIdentifier),
                                hiddenLabel: L10n.string("settings.hiddenApps.hidden", language: store.appLanguage)
                            ) {
                                toggleSelection(for: row.bundleIdentifier)
                            }

                            if index < hiddenAppRows.count - 1 {
                                Divider()
                                    .padding(.leading, HiddenAppsListLayout.separatorLeadingInset)
                            }
                        }
                    }
                }

                if hiddenAppRows.isEmpty {
                    Text(L10n.string("settings.hiddenApps.empty", language: store.appLanguage))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            hiddenAppsControlBar
        }
        .frame(height: HiddenAppsListLayout.listHeight)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: HiddenAppsListLayout.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: HiddenAppsListLayout.cornerRadius, style: .continuous)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
    }

    private var hiddenAppsControlBar: some View {
        HStack(spacing: 0) {
            Button {
                addHiddenApp()
            } label: {
                Image(systemName: "plus")
                    .frame(
                        width: HiddenAppsListLayout.controlButtonWidth,
                        height: HiddenAppsListLayout.controlButtonHeight
                    )
            }
            .buttonStyle(.borderless)
            .help(L10n.string("settings.hiddenApps.add", language: store.appLanguage))
            .accessibilityLabel(L10n.string("settings.hiddenApps.add", language: store.appLanguage))

            Button {
                removeSelectedHiddenApps()
            } label: {
                Image(systemName: "minus")
                    .frame(
                        width: HiddenAppsListLayout.controlButtonWidth,
                        height: HiddenAppsListLayout.controlButtonHeight
                    )
            }
            .buttonStyle(.borderless)
            .disabled(selectedHiddenAppBundleIdentifiers.isEmpty)
            .help(L10n.string("settings.hiddenApps.remove", language: store.appLanguage))
            .accessibilityLabel(L10n.string("settings.hiddenApps.remove", language: store.appLanguage))

            Spacer()
        }
        .padding(.horizontal, HiddenAppsListLayout.controlBarHorizontalPadding)
        .frame(height: HiddenAppsListLayout.controlBarHeight)
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
        let panel = ApplicationOpenPanel.make(title: L10n.string("settings.hiddenApps.add", language: store.appLanguage))

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
                    name: app.localizedName ?? app.bundleIdentifier ?? L10n.string("app.unknown", language: store.appLanguage),
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

#if DEBUG
#Preview("Hidden Apps Detail") {
    SettingsDetailPreviewSurface(height: 520) {
        HiddenAppsSettingsView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.HiddenAppsDetailPreview")
        )
    }
}
#endif

private enum HiddenAppsListLayout {
    static let descriptionSpacing: CGFloat = 10
    static let listHeight: CGFloat = 320
    static let cornerRadius: CGFloat = 8
    static let iconSize: CGFloat = 28
    static let iconTextSpacing: CGFloat = 10
    static let rowHorizontalPadding: CGFloat = 12
    static let rowVerticalPadding: CGFloat = 6
    static let controlBarHeight: CGFloat = 28
    static let controlBarHorizontalPadding: CGFloat = 6
    static let controlButtonWidth: CGFloat = 24
    static let controlButtonHeight: CGFloat = 22

    static var separatorLeadingInset: CGFloat {
        rowHorizontalPadding + iconSize + iconTextSpacing
    }
}

private struct HiddenAppRow: View {
    let row: HiddenAppRowModel
    let isSelected: Bool
    @Binding var isHidden: Bool
    let hiddenLabel: String
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: HiddenAppsListLayout.iconTextSpacing) {
            if let icon = row.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(
                        width: HiddenAppsListLayout.iconSize,
                        height: HiddenAppsListLayout.iconSize
                    )
            }

            Text(row.name)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Toggle(hiddenLabel, isOn: $isHidden)
                .labelsHidden()
                .toggleStyle(.switch)
                .help(hiddenLabel)
                .accessibilityLabel(hiddenLabel)
                .accessibilityIdentifier("hidden-app-toggle-\(row.bundleIdentifier)")
        }
        .padding(.horizontal, HiddenAppsListLayout.rowHorizontalPadding)
        .padding(.vertical, HiddenAppsListLayout.rowVerticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .background(isSelected ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
