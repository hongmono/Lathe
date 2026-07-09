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

    /// 캡처 해상도 상한(긴 변 px). 타일은 이보다 작게 표시되므로 원본 통째 캡처는 낭비.
    /// ponytail: 800 고정. 창이 적어 타일이 아주 클 때만 살짝 soft — 그 경우 캡처 비용도 낮아 무관.
    private static func captureSize(for size: CGSize) -> (Int, Int) {
        let maxSide: CGFloat = 800
        let w = max(size.width, 1), h = max(size.height, 1)
        let scale = min(1, maxSide / max(w, h))
        return (max(1, Int(w * scale)), max(1, Int(h * scale)))
    }

    /// 창 하나의 현재 화면을 캡처. 실패 시 nil.
    private static func captureOne(_ window: SCWindow) async -> (Int, NSImage)? {
        guard window.frame.width > 0, window.frame.height > 0 else { return nil }
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        let (w, h) = captureSize(for: window.frame.size)
        config.width = w
        config.height = h
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
