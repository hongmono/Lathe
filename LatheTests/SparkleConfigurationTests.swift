import XCTest

final class SparkleConfigurationTests: XCTestCase {

    func test_appBundleContainsSparkleConfiguration() throws {
        let appBundle = try XCTUnwrap(Bundle(identifier: "com.hongmono.Lathe"))

        XCTAssertEqual(
            appBundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
            "https://github.com/hongmono/Lathe/releases/latest/download/appcast.xml"
        )
        let sparklePublicKey = try XCTUnwrap(appBundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String)
        XCTAssertFalse(sparklePublicKey.contains("$("))
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUEnableAutomaticChecks") as? Bool, true)
        XCTAssertEqual(appBundle.object(forInfoDictionaryKey: "SUScheduledCheckInterval") as? Int, 86_400)
    }
}
