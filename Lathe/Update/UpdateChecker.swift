import Foundation

struct UpdateInfo: Equatable {
    let version: String
    let tagName: String
    let htmlURL: URL
    let publishedAt: Date?
}

enum UpdateCheckError: Error {
    case invalidResponse
    case decodingFailed
}

enum UpdateChecker {
    static let repoOwner = "hongmono"
    static let repoName = "Lathe"

    static func currentVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static func fetchLatestRelease() async throws -> UpdateInfo {
        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var req = URLRequest(url: url)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("Lathe/\(currentVersion())", forHTTPHeaderField: "User-Agent")
        req.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateCheckError.invalidResponse
        }

        struct Payload: Decodable {
            let tagName: String
            let htmlURL: URL
            let publishedAt: Date?
            enum CodingKeys: String, CodingKey {
                case tagName = "tag_name"
                case htmlURL = "html_url"
                case publishedAt = "published_at"
            }
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Payload.self, from: data) else {
            throw UpdateCheckError.decodingFailed
        }

        let version = payload.tagName.hasPrefix("v")
            ? String(payload.tagName.dropFirst())
            : payload.tagName
        return UpdateInfo(
            version: version,
            tagName: payload.tagName,
            htmlURL: payload.htmlURL,
            publishedAt: payload.publishedAt
        )
    }

    static func isNewer(latest: String, than current: String) -> Bool {
        let lhs = latest.split(separator: ".").compactMap { Int($0) }
        let rhs = current.split(separator: ".").compactMap { Int($0) }
        let count = max(lhs.count, rhs.count)
        for i in 0..<count {
            let a = i < lhs.count ? lhs[i] : 0
            let b = i < rhs.count ? rhs[i] : 0
            if a != b { return a > b }
        }
        return false
    }
}
