import AppKit
import CoreGraphics
import ScreenCaptureKit

struct WindowThumbnailProvider {
    /// non-Sendable SCWindow를 병렬 Task로 넘기기 위한 박스. 읽기 전용 사용이라 안전.
    private struct SendableWindow: @unchecked Sendable { let window: SCWindow }

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

        // 창별 캡처는 서로 독립적이라 병렬로. 전체 소요 ≈ 가장 느린 창 하나(순차 합산 아님).
        // SCWindow는 캡처 중 읽기 전용으로만 접근하므로 병렬 Task로 넘겨도 안전(@unchecked).
        return await withTaskGroup(of: (Int, NSImage)?.self) { group in
            for window in targets {
                let boxed = SendableWindow(window: window)
                group.addTask { await Self.captureOne(boxed.window) }
            }
            var acc: [Int: NSImage] = [:]
            for await item in group {
                if let (id, image) = item { acc[id] = image }
            }
            return acc
        }
    }

    /// 창 하나의 현재 화면을 캡처. 실패 시 nil.
    private static func captureOne(_ window: SCWindow) async -> (Int, NSImage)? {
        guard window.frame.width > 0, window.frame.height > 0 else { return nil }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width)
        config.height = Int(window.frame.height)
        config.showsCursor = false
        guard let cgImage = try? await SCScreenshotManager.captureImage(
            contentFilter: filter, configuration: config
        ) else {
            return nil
        }
        return (Int(window.windowID),
                NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)))
    }
}
