import AppKit

struct HiddenAppRowModel: Identifiable, Equatable {
    let bundleIdentifier: String
    let name: String
    let icon: NSImage?
    let isHidden: Bool

    var id: String { bundleIdentifier }

    init(option: AppExclusionOption, isHidden: Bool) {
        self.bundleIdentifier = option.bundleIdentifier
        self.name = option.name
        self.icon = option.icon
        self.isHidden = isHidden
    }

    static func rows(from options: [AppExclusionOption],
                     excludedBundleIdentifiers: Set<String>) -> [HiddenAppRowModel] {
        options.map { option in
            HiddenAppRowModel(
                option: option,
                isHidden: excludedBundleIdentifiers.contains(option.bundleIdentifier)
            )
        }
    }

    static func == (lhs: HiddenAppRowModel, rhs: HiddenAppRowModel) -> Bool {
        lhs.bundleIdentifier == rhs.bundleIdentifier
            && lhs.name == rhs.name
            && lhs.isHidden == rhs.isHidden
    }
}
