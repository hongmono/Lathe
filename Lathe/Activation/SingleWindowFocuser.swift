import ApplicationServices
import CoreGraphics
import CoreServices
import Foundation

/// SkyLight 비공개 API를 이용해 "선택한 창 하나만" 다른 앱 위로 올린다.
/// 앱 단위 활성화(`NSRunningApplication.activate`)를 거치지 않으므로 형제 창들이
/// 함께 따라 올라오지 않는다. AltTab·yabai 등이 사용하는 방식이다.
///
/// 비공개 심볼은 런타임(`dlsym`)으로만 조회하며, 하나라도 없거나 호출이 실패하면
/// `false`를 돌려 호출부가 공개 API 폴백으로 처리하도록 한다.
enum SingleWindowFocuser {

    private enum SLPSMode: UInt32 {
        case userGenerated = 0x200
    }

    private typealias SetFrontProcessFunction =
        @convention(c) (UnsafeMutablePointer<ProcessSerialNumber>, CGWindowID, UInt32) -> CGError
    private typealias PostEventRecordFunction =
        @convention(c) (UnsafeMutablePointer<ProcessSerialNumber>, UnsafeMutablePointer<UInt8>) -> CGError
    private typealias GetProcessForPIDFunction =
        @convention(c) (pid_t, UnsafeMutablePointer<ProcessSerialNumber>) -> OSStatus

    private static let setFrontProcess: SetFrontProcessFunction? = symbol("_SLPSSetFrontProcessWithOptions")
    private static let postEventRecord: PostEventRecordFunction? = symbol("SLPSPostEventRecordTo")
    private static let getProcessForPID: GetProcessForPIDFunction? = symbol("GetProcessForPID")

    static var isAvailable: Bool {
        setFrontProcess != nil && postEventRecord != nil && getProcessForPID != nil
    }

    /// 지정한 창만 전면으로 끌어올린다. 비공개 API를 쓸 수 없거나 실패하면 `false`.
    @discardableResult
    static func focus(windowID: CGWindowID, processIdentifier pid: pid_t, axWindow: AXUIElement) -> Bool {
        guard let setFrontProcess, let postEventRecord, let getProcessForPID else { return false }

        var psn = ProcessSerialNumber()
        guard getProcessForPID(pid, &psn) == noErr else { return false }
        guard setFrontProcess(&psn, windowID, SLPSMode.userGenerated.rawValue) == .success else { return false }

        makeKeyWindow(windowID: windowID, psn: psn, post: postEventRecord)
        AXUIElementPerformAction(axWindow, kAXRaiseAction as CFString)
        return true
    }

    /// 윈도우 서버가 해당 창을 key 윈도우로 인식하도록 두 개의 합성 이벤트를 보낸다.
    /// 바이트 레이아웃은 SkyLight가 기대하는 고정 포맷이다.
    private static func makeKeyWindow(windowID: CGWindowID,
                                      psn: ProcessSerialNumber,
                                      post: PostEventRecordFunction) {
        var psn = psn
        var wid = windowID
        for marker: UInt8 in [0x01, 0x02] {
            var bytes = [UInt8](repeating: 0, count: 0xf8)
            bytes[0x04] = 0xf8
            bytes[0x08] = marker
            bytes[0x3a] = 0x10
            withUnsafeBytes(of: &wid) { raw in
                for index in 0..<MemoryLayout<CGWindowID>.size {
                    bytes[0x3c + index] = raw[index]
                }
            }
            for index in 0..<0x10 { bytes[0x20 + index] = 0xff }
            _ = bytes.withUnsafeMutableBufferPointer { buffer in
                post(&psn, buffer.baseAddress!)
            }
        }
    }

    private static func symbol<T>(_ name: String) -> T? {
        guard let handle = dlopen(nil, RTLD_NOW) else { return nil }
        defer { dlclose(handle) }
        guard let pointer = dlsym(handle, name) else { return nil }
        return unsafeBitCast(pointer, to: T.self)
    }
}
