import Foundation

struct WindowEntry: Identifiable, Equatable {
    let id: Int
    let title: String
    let pathSummary: String?
    let isMinimized: Bool

    var isDisplayable: Bool {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = pathSummary?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !name.isEmpty || !path.isEmpty
    }

    var displayTitle: String {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = pathSummary?.trimmingCharacters(in: .whitespacesAndNewlines)

        if !name.isEmpty {
            if let path, !path.isEmpty {
                if path.hasSuffix("/\(name)") {
                    let directory = String(path.dropLast(name.count + 1))
                    if !directory.isEmpty {
                        return "\(name) (\(directory))"
                    }
                } else if shouldAppendPath(name: name, path: path) {
                    return "\(name) (\(path))"
                }
            }
            return name
        }
        if let path, !path.isEmpty {
            return path
        }
        return L10n.string("window.untitled")
    }

    private func shouldAppendPath(name: String, path: String) -> Bool {
        if name == path { return false }
        if name.contains(path) { return false }
        return true
    }
}
