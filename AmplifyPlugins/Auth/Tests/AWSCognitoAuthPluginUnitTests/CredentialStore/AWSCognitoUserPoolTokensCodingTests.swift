//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AWSCognitoUserPoolTokensCodingTests: XCTestCase, @unchecked Sendable {

    /// Test that the persisted token JSON keeps its keys
    ///
    /// - Given: User pool tokens with an expiration
    /// - When:
    ///    - They're encoded
    /// - Then:
    ///    - The JSON has exactly the keys earlier versions wrote, including `expiration`
    ///
    func testEncode_usesPersistedKeys() throws {
        let tokens = AWSCognitoUserPoolTokens(
            idToken: "idToken",
            accessToken: "accessToken",
            refreshToken: "refreshToken",
            legacyExpiration: Date(timeIntervalSinceReferenceDate: 1_000)
        )

        let data = try JSONEncoder().encode(tokens)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertEqual(Set(json.keys), ["idToken", "accessToken", "refreshToken", "expiration"])
        XCTAssertEqual(json["expiration"] as? Double, 1_000)
    }

    /// Test that tokens saved by earlier versions still decode
    ///
    /// - Given: Token JSON in the format earlier versions persisted
    /// - When:
    ///    - It's decoded
    /// - Then:
    ///    - Every value, including the expiration, is restored
    ///
    func testDecode_persistedJSON_restoresExpiration() throws {
        let json = #"{"idToken":"idToken","accessToken":"accessToken","refreshToken":"refreshToken","expiration":1000}"#

        let tokens = try JSONDecoder().decode(AWSCognitoUserPoolTokens.self, from: Data(json.utf8))

        XCTAssertEqual(tokens.idToken, "idToken")
        XCTAssertEqual(tokens.accessToken, "accessToken")
        XCTAssertEqual(tokens.refreshToken, "refreshToken")
        XCTAssertEqual(tokens.legacyExpiration, Date(timeIntervalSinceReferenceDate: 1_000))
    }
}
