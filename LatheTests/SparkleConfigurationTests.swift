import XCTest

final class SparkleConfigurationTests: XCTestCase {

    func test_appBundleContainsSparkleConfiguration() throws {
        let appBundle = Bundle.main

        XCTAssertEqual(
            appBundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            "https://github.com/hongmono/Lathe/releases/latest/download/appcast.xml"
        )
        let sparklePublicKey = try XCTUnwrap(appBundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String)
        XCTAssertEqual(sparklePublicKey, "2VzsRT4zVK1HpMKb6p0gOIVNSXHAadl54RQmv29Sxu8=")
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool, true)
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUScheduledCheckInterval") as? Int, 86_400)
    }

    func test_debugAppUsesDistinctBundleIdentifier() {
        XCTAssertEqual(Bundle.main.bundleIdentifier, "com.hongmono.Lathe.debug")
    }
}
