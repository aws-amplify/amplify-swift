//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AmplifyCognitoASF

final class UserContextDataEncoderTests: XCTestCase {

    /// Test that the time zone is sent as its signed offset in hours and minutes
    ///
    /// - Given: Offsets from GMT, in seconds
    /// - When:
    ///    - each is formatted
    /// - Then:
    ///    - each is `±hh:mm`
    ///
    func testTheTimeZoneIsItsSignedOffsetInHoursAndMinutes() {
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: -25_200), "-07:00")
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: 25_200), "+07:00")
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: 0), "+00:00")
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: 19_800), "+05:30")
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: -12_600), "-03:30")
        XCTAssertEqual(UserContextDataEncoder.timeZoneOffset(seconds: 45_900), "+12:45")
    }

    /// Test that the signature is the app client ID's HMAC of the version and the payload
    ///
    /// - Given: A payload and an app client ID
    /// - When:
    ///    - the payload is signed
    /// - Then:
    ///    - the signature is the base64 HMAC-SHA256, keyed by the app client ID, of "IOS20171114" and the payload
    ///
    func testTheSignatureIsTheClientIdsHMACOfTheVersionAndThePayload() throws {
        let signature = try UserContextDataEncoder.calculateSecretHash(
            contextJson: "contextJson",
            clientId: "clientId"
        )

        XCTAssertEqual(signature, "J6M4nj6vyYJo9xWVx8J7/Xrfy12UHTuuhHv+TEfwXmo=")
    }

    /// Test that an app client ID that isn't ASCII can't sign
    ///
    /// - Given: An app client ID that has no ASCII representation
    /// - When:
    ///    - a payload is signed with it
    /// - Then:
    ///    - `ASFError.hashKey` is thrown
    ///
    func testAClientIdThatIsNotASCIIThrowsHashKey() {
        XCTAssertThrowsError(
            try UserContextDataEncoder.calculateSecretHash(contextJson: "contextJson", clientId: "🕺🏼")
        ) { error in
            XCTAssertEqual(error as? ASFError, .hashKey)
        }
    }
}
