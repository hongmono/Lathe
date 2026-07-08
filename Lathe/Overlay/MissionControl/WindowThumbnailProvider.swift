import AppKit
import CoreGraphics
import ScreenCaptureKit

struct WindowThumbnailProvider {
    /// 화면 기록 권한 여부(비차단).
    static func hasPermission() -> Bool { CGPreflightScreenCaptureAccess() }

    /// 권한 요청(최초 1회 시스템 프롬프트). 결과와 무관하게 오버레이는 폴백 동작.
    @discardableResult
    static func requestPermission() -> Bool { CGRequestScreenCaptureAccess() }

    /// 주어진 cgWindowID들의 현재 화면 이미지를 1회 캡처. 권한 없거나 실패한 창은 결과에서 빠진다.
    func capture(windowIDs: [Int]) async -> [Int: NSImage] {
        guard Self.hasPermission() else { return [:] }
        guard let content = try? await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true
        ) else {
            return [:]
        }
        let wanted = Set(windowIDs.map { UInt32($0) })
        let targets = content.windows.filter { wanted.contains($0.windowID) }

        var result: [Int: NSImage] = [:]
        for window in targets {
            guard window.frame.width > 0, window.frame.height > 0 else { continue }
            let filter = SCContentFilter(desktopIndependentWindow: window)
            let config = SCStreamConfiguration()
            config.width = Int(window.frame.width)
            config.height = Int(window.frame.height)
            config.showsCursor = false
            guard let cgImage = try? await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: config
            ) else {
                continue
            }
            result[Int(window.windowID)] = NSImage(
                cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)
            )
        }
        return result
    }
}
