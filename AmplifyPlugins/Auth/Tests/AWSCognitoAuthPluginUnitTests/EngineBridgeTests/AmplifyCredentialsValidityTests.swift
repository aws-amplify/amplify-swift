//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// `AmplifyCredentials.areValid(at:)`, moved from the plugin's `AmplifyCredentials+CognitoSession.swift`
/// into the engine with an `at:` parameter, so the Cognito client can pass its own clock. The plugin still calls
/// `areValid()`, which reads the current time, as before.
class AmplifyCredentialsValidityTests: XCTestCase {

    /// Every token and AWS credential in the frozen payloads expires at this instant.
    private let expiry = Date(timeIntervalSince1970: 2_000_000_000)

    /// Test that validity is measured from the given instant, with the two-minute buffer
    ///
    /// - Given: The frozen payload of every kind, whose tokens and AWS credentials all expire at the same instant
    /// - When:
    ///    - `areValid(at:)` is asked well before the expiry, just outside and just inside the two-minute buffer,
    ///      and after the expiry
    /// - Then:
    ///    - Every kind with credentials is valid only outside the buffer; `noCredentials` is never valid
    ///
    func testAreValidAt_measuresFromTheGivenInstantWithTheBuffer() throws {
        let buffer = AmplifyCredentials.expiryBufferInSeconds
        XCTAssertEqual(buffer, 120)
        let instants: [(Date, Bool)] = [
            (expiry.addingTimeInterval(-86_400), true),
            (expiry.addingTimeInterval(-buffer - 1), true),
            (expiry.addingTimeInterval(-buffer + 1), false),
            (expiry.addingTimeInterval(1), false)
        ]
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let credentials = try XCTUnwrap(AmplifyCredentialsPayloadFixtures.expected(caseName))
            for (instant, validWithCredentials) in instants {
                let expected = caseName == "noCredentials" ? false : validWithCredentials
                XCTAssertEqual(credentials.areValid(at: instant), expected, "\(caseName) at \(instant)")
            }
        }
    }

    /// Test that the default instant is the current time, as the plugin has always used
    ///
    /// - Given: The frozen payloads, which expire in 2033, and the same payloads with already-expired credentials
    /// - When:
    ///    - `areValid()` is called without an instant
    /// - Then:
    ///    - It agrees with `areValid(at: Date())`: the frozen ones are valid, the expired ones are not
    ///
    func testAreValid_defaultsToNow() throws {
        for caseName in AmplifyCredentialsPayloadFixtures.caseNames {
            let credentials = try XCTUnwrap(AmplifyCredentialsPayloadFixtures.expected(caseName))
            XCTAssertEqual(credentials.areValid(), credentials.areValid(at: Date()), caseName)
            XCTAssertEqual(credentials.areValid(), caseName != "noCredentials", caseName)
        }

        let expired = AmplifyCredentials.identityPoolOnly(
            identityID: "id",
            credentials: EngineAWSCredentials(
                accessKeyId: "a",
                secretAccessKey: "s",
                sessionToken: "t",
                expiration: Date().addingTimeInterval(-1)
            )
        )
        XCTAssertFalse(expired.areValid())
        XCTAssertTrue(expired.areValid(at: Date().addingTimeInterval(-3_600)))
    }

    /// Test that the forks' `doesExpire(in:at:)` measures from the given instant
    ///
    /// - Given: The frozen user pool tokens and AWS credentials, both expiring at the same instant
    /// - When:
    ///    - `doesExpire(in:at:)` is asked just before and just after the expiry, with and without a buffer
    /// - Then:
    ///    - The answer depends only on the instant plus the buffer, for both types
    ///
    func testDoesExpireAt_measuresFromTheGivenInstant() throws {
        let fixture = try XCTUnwrap(AmplifyCredentialsPayloadFixtures.expected("userPoolAndIdentityPool"))
        guard case .userPoolAndIdentityPool(let signedInData, _, let awsCredentials) = fixture else {
            return XCTFail("unexpected fixture \(fixture)")
        }
        let tokens = signedInData.cognitoUserPoolTokens
        let before = expiry.addingTimeInterval(-10)
        let after = expiry.addingTimeInterval(10)

        XCTAssertFalse(tokens.doesExpire(at: before))
        XCTAssertTrue(tokens.doesExpire(at: after))
        XCTAssertTrue(tokens.doesExpire(in: 20, at: before))
        XCTAssertFalse(awsCredentials.doesExpire(at: before))
        XCTAssertTrue(awsCredentials.doesExpire(at: after))
        XCTAssertTrue(awsCredentials.doesExpire(in: 20, at: before))
    }
}
