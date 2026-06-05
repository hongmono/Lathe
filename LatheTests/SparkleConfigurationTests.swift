import XCTest

final class SparkleConfigurationTests: XCTestCase {

    func test_appBundleContainsSparkleConfiguration() throws {
        let appBundle = try XCTUnwrap(Bundle(identifier: "com.hongmono.Lathe"))

        XCTAssertEqual(
            appBundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            "https://github.com/hongmono/Lathe/releases/latest/download/appcast.xml"
        )
        XCTAssertEqual(
            appBundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
            "2VzsRT4zVK1HpMKb6p0gOIVNSXHAadl54RQmv29Sxu8="
        )
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool, true)
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUScheduledCheckInterval") as? Int, 86_400)
    }
}
