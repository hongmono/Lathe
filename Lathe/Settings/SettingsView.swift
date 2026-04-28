import SwiftUI

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
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 440)
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
