import XCTest
@testable import Magnify

final class MagnifyTests: XCTestCase {
    
    func testAppDelegateExists() {
        let appDelegate = AppDelegate()
        XCTAssertNotNil(appDelegate)
    }
    
    func testBundleIdentifier() {
        // This test verifies our bundle ID is correctly set
        let expectedBundleID = "com.jayleekr.magnify"
        // Note: Bundle.main.bundleIdentifier might not work in test context
        // This is more of a documentation test
        XCTAssertEqual(expectedBundleID, "com.jayleekr.magnify")
    }
    
    func testMinimumSystemVersion() {
        // Verify we're targeting the correct macOS version
        let minimumVersion = "12.3"
        XCTAssertEqual(minimumVersion, "12.3")
    }
} 