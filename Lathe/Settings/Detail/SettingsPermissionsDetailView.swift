import AppKit
import SwiftUI

struct SettingsPermissionsDetailView: View {
    @ObservedObject var store: SettingsStore
    private let accessibilityStatusProvider: () -> Bool
    @State private var isAccessibilityTrusted: Bool

    init(store: SettingsStore,
         accessibilityStatusProvider: @escaping () -> Bool = { AccessibilityChecker.isTrusted }) {
        self.store = store
        self.accessibilityStatusProvider = accessibilityStatusProvider
        _isAccessibilityTrusted = State(initialValue: accessibilityStatusProvider())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SettingsViewLayout.detailGroupSpacing) {
            Label(L10n.string("settings.permissions.section", language: store.appLanguage),
                  systemImage: "hand.raised")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(L10n.string("settings.permissions.summary", language: store.appLanguage))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: SettingsViewLayout.detailSectionBreakHeight)

            permissionRow

            HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                Button(L10n.string("settings.permissions.openAccessibility", language: store.appLanguage)) {
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))

                Button(L10n.string("settings.permissions.refresh", language: store.appLanguage)) {
                    refreshStatus()
                }
            }

            Text(L10n.string("settings.permissions.restartNote", language: store.appLanguage))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer().frame(height: SettingsViewLayout.detailSectionBreakHeight)

            Label(L10n.string("settings.permissions.notRequested.title", language: store.appLanguage),
                  systemImage: "checkmark.shield")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(L10n.string("settings.permissions.notRequested.description", language: store.appLanguage))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear(perform: refreshStatus)
    }

    private var permissionRow: some View {
        HStack(alignment: .top, spacing: SettingsViewLayout.detailRowSpacing) {
            Image(systemName: isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.title3)
                .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
                .frame(width: SettingsPermissionsDetailLayout.statusIconWidth, alignment: .center)

            VStack(alignment: .leading, spacing: SettingsPermissionsDetailLayout.rowTextSpacing) {
                HStack(spacing: SettingsViewLayout.detailRowSpacing) {
                    Text(L10n.string("settings.permissions.accessibility.name", language: store.appLanguage))
                        .font(.body)
                        .fontWeight(.medium)

                    Text(L10n.string("settings.permissions.required", language: store.appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(L10n.string("settings.permissions.accessibility.description", language: store.appLanguage))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: SettingsViewLayout.detailRowSpacing)

            Label(statusTitle, systemImage: isAccessibilityTrusted ? "checkmark" : "xmark")
                .font(.callout)
                .foregroundStyle(isAccessibilityTrusted ? .green : .orange)
        }
        .padding(.vertical, SettingsPermissionsDetailLayout.rowVerticalPadding)
    }

    private var statusTitle: String {
        if isAccessibilityTrusted {
            return L10n.string("settings.permissions.status.granted", language: store.appLanguage)
        }
        return L10n.string("settings.permissions.status.missing", language: store.appLanguage)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        AccessibilityChecker.requestTrust()
        refreshStatus()
    }

    private func refreshStatus() {
        AppState.shared.onRetryPermission?()
        isAccessibilityTrusted = accessibilityStatusProvider()
    }
}

private enum SettingsPermissionsDetailLayout {
    static let statusIconWidth: CGFloat = 24
    static let rowTextSpacing: CGFloat = 4
    static let rowVerticalPadding: CGFloat = 8
}

#if DEBUG
#Preview("Permissions Detail - Missing") {
    SettingsDetailPreviewSurface {
        SettingsPermissionsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsPermissionsDetailMissingPreview"),
            accessibilityStatusProvider: { false }
        )
    }
}

#Preview("Permissions Detail - Granted") {
    SettingsDetailPreviewSurface {
        SettingsPermissionsDetailView(
            store: SettingsPreviewStore.makeStore(suiteName: "Lathe.SettingsPermissionsDetailGrantedPreview"),
            accessibilityStatusProvider: { true }
        )
    }
}
#endif
