import CoreGraphics
import Foundation

protocol CurrentSpaceWindowProviding {
    func processIdentifiers() -> Set<pid_t>
}

struct CurrentSpaceWindowProvider: CurrentSpaceWindowProviding {

    func processIdentifiers() -> Set<pid_t> {
        guard let windows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return []
        }

        return Self.processIdentifiers(fromWindowList: windows)
    }

    static func processIdentifiers(fromWindowList windows: [[String: Any]]) -> Set<pid_t> {
        let ownerPIDKey = kCGWindowOwnerPID as String
        let layerKey = kCGWindowLayer as String

        return Set(windows.compactMap { window -> pid_t? in
            guard let layer = (window[layerKey] as? NSNumber)?.intValue, layer == 0 else {
                return nil
            }
            guard let ownerPID = (window[ownerPIDKey] as? NSNumber)?.int32Value else {
                return nil
            }

            let pid = pid_t(ownerPID)
            return pid > 0 ? pid : nil
        })
    }
}
