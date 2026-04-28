import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            appearanceTab
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            carouselTab
                .tabItem { Label("Carousel", systemImage: "rectangle.stack") }
        }
        .frame(width: 520, height: 380)
    }

    private var generalTab: some View {
        Form {
            Toggle("Launch Lathe at login", isOn: $store.launchAtLogin)
            Text("Lathe will start automatically when you sign in. You can revoke this from System Settings → General → Login Items.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
    }

    private var appearanceTab: some View {
        Form {
            Picker("Appearance", selection: $store.appearance) {
                ForEach(Appearance.allCases) { a in
                    Text(a.label).tag(a)
                }
            }
            .pickerStyle(.inline)
        }
        .formStyle(.grouped)
    }

    private var carouselTab: some View {
        Form {
            Section {
                slider(label: "Card width",
                       value: $store.cardWidth,
                       range: 80...180,
                       suffix: "pt")
                slider(label: "Card height",
                       value: $store.cardHeight,
                       range: 110...230,
                       suffix: "pt")
                slider(label: "Pivot distance",
                       value: $store.pivotDistance,
                       range: 220...520,
                       suffix: "pt")
                slider(label: "Angular step",
                       value: $store.angularStep,
                       range: 6...28,
                       suffix: "°")
            }
            HStack {
                Spacer()
                Button("Restore defaults") {
                    store.resetCarouselDefaults()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func slider(label: String,
                        value: Binding<Double>,
                        range: ClosedRange<Double>,
                        suffix: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 120, alignment: .leading)
            Slider(value: value, in: range)
            Text("\(Int(value.wrappedValue))\(suffix)")
                .monospacedDigit()
                .frame(width: 56, alignment: .trailing)
                .foregroundStyle(.secondary)
        }
    }
}
