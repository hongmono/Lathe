import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

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
                HStack {
                    Spacer()
                    Button("Restore defaults") {
                        store.resetCarouselDefaults()
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
        .frame(width: 460, height: 540)
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
}
