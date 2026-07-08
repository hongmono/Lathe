import Foundation

enum WindowPathSummary {
    static func summarize(_ url: URL) -> String? {
        if url.isFileURL {
            return summarizeFilePath(url.path)
        }
        guard let host = url.host, !host.isEmpty else { return nil }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.isEmpty {
            return host
        }
        let parts = path.split(separator: "/").map(String.init)
        if parts.count <= 2 {
            return ([host] + parts).joined(separator: "/")
        }
        return "\(host)/…/\(parts.last!)"
    }

    static func summarizeFilePath(_ path: String) -> String? {
        let standardized = (path as NSString).standardizingPath
        guard !standardized.isEmpty else { return nil }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let relative: String
        if standardized == home {
            return "~"
        } else if standardized.hasPrefix(home + "/") {
            relative = String(standardized.dropFirst(home.count + 1))
        } else {
            relative = String(standardized.drop(while: { $0 == "/" }))
        }
        return abbreviatePath(relative, maxComponents: 2)
    }

    static func abbreviatePath(_ path: String, maxComponents: Int) -> String {
        let parts = path.split(separator: "/").map(String.init)
        guard !parts.isEmpty else { return path }
        guard parts.count > maxComponents else { return path }
        return "…/" + parts.suffix(maxComponents).joined(separator: "/")
    }

    static func url(fromDocumentValue value: CFTypeRef) -> URL? {
        if let url = value as? URL {
            return url
        }
        if let string = value as? String {
            if let url = URL(string: string), url.scheme != nil {
                return url
            }
            if string.hasPrefix("/") {
                return URL(fileURLWithPath: string)
            }
        }
        return nil
    }
}
