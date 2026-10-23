//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Differential test for the UTC time zone the legacy migration parses AWSMobileClient token expirations in
/// the engine's constant replaces Amplify's `TimeZone.utc`.
final class EngineUTCTimeZoneTests: XCTestCase {

    /// Test that the engine's UTC time zone equals Amplify's
    ///
    /// - Given: `MigrateLegacyCredentialStore.utcTimeZone` and `TimeZone.utc`
    /// - When:
    ///    - Both are compared, and both parse the same AWSMobileClient expiration string
    /// - Then:
    ///    - The time zones are equal, and so are the parsed dates
    ///
    func testEngineUTCTimeZoneEqualsAmplifys() throws {
        XCTAssertEqual(MigrateLegacyCredentialStore.utcTimeZone, TimeZone.utc)
        XCTAssertEqual(MigrateLegacyCredentialStore.utcTimeZone.secondsFromGMT(), 0)

        func parse(_ timeZone: TimeZone) -> Date? {
            let formatter = DateFormatter()
            formatter.timeZone = timeZone
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            return formatter.date(from: "2024-03-10T02:30:00Z")
        }
        let engine = try XCTUnwrap(parse(MigrateLegacyCredentialStore.utcTimeZone))
        XCTAssertEqual(engine, parse(TimeZone.utc))
        XCTAssertEqual(engine.timeIntervalSince1970, 1_710_037_800)
    }
}
