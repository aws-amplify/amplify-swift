//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// Where the identity policy comes from, and how `HostedUIError.unexpectedIdentity` maps to the engine's and
/// the plugin's errors.
class HostedUIIdentityMismatchTests: XCTestCase {

    /// Test that the plugin's environments carry no policy
    ///
    /// - Given: A hosted-UI environment built as the plugin builds it, without an identity policy
    /// - When:
    ///    - Its policy is read
    /// - Then:
    ///    - It is `.none`, which verifies nothing; one built with a policy keeps it
    ///
    func testEnvironmentPolicyDefaultsToNone() {
        XCTAssertEqual(Self.environment(policy: nil).identityPolicy, .none)
        let policy = HostedUIIdentityPolicy(verifiesTokenClaims: true, expectedIdentity: "someone")
        XCTAssertEqual(Self.environment(policy: policy).identityPolicy, policy)
    }

    /// Test how every mismatch maps to the engine's error
    ///
    /// - Given: A mismatch for every reason
    /// - When:
    ///    - Its `HostedUIError` is mapped to `EngineAuthError` and to the plugin's `AuthError`
    /// - Then:
    ///    - Each is `.service`, carrying the mismatch as its underlying error; identity reasons and response
    ///      reasons have different descriptions, neither of which contains the returned user
    ///
    func testEveryReasonMapsToAServiceErrorCarryingTheMismatch() throws {
        for reason in HostedUIIdentityMismatch.Reason.allCases {
            let mismatch = HostedUIIdentityMismatch(
                reason: reason,
                expected: "expectedUser",
                returnedUsername: "returnedUser",
                returnedUserId: "returned-sub"
            )
            let error = HostedUIError.unexpectedIdentity(mismatch)
            guard case .service(let description, let suggestion, let underlying) = error.engineError else {
                XCTFail("\(reason): expected .service, got \(error.engineError)")
                continue
            }
            XCTAssertEqual(underlying as? HostedUIIdentityMismatch, mismatch, "\(reason)")
            XCTAssertEqual(suggestion, HostedUIIdentityMismatch.recoverySuggestion, "\(reason)")
            let expected = mismatch.isIdentityMismatch
                ? HostedUIIdentityMismatch.identityMismatchDescription
                : HostedUIIdentityMismatch.unverifiedResponseDescription
            XCTAssertEqual(description, expected, "\(reason)")
            for identity in ["expectedUser", "returnedUser", "returned-sub"] {
                XCTAssertFalse(description.contains(identity), "\(reason)")
                XCTAssertFalse(suggestion.contains(identity), "\(reason)")
            }

            guard case .service(let authDescription, _, _) = error.authError else {
                XCTFail("\(reason): expected AuthError.service")
                continue
            }
            XCTAssertEqual(authDescription, description, "\(reason)")
        }
        XCTAssertNotEqual(
            HostedUIIdentityMismatch.identityMismatchDescription,
            HostedUIIdentityMismatch.unverifiedResponseDescription
        )
        XCTAssertTrue(HostedUIIdentityMismatch.recoverySuggestion.contains("prompt"))
    }

    /// Test that no printed form of a mismatch carries an identity
    ///
    /// - Given: A mismatch holding an expected user, a returned username and a returned `sub`
    /// - When:
    ///    - It is printed every way a log line can print it: interpolated, `String(reflecting:)`, `dump`, as the
    ///      underlying error of `EngineAuthError` and `AuthError`, and inside `HostedUISignInState.error`'s debug
    ///      dictionary
    /// - Then:
    ///    - None of the output contains any of the three values, and each names the reason
    ///
    func testPrintedFormsNameOnlyTheReason() {
        let mismatch = HostedUIIdentityMismatch(
            reason: .notExpectedIdentity,
            expected: "alice@example.com",
            returnedUsername: "bob",
            returnedUserId: "sub-123"
        )
        let hostedUIError = HostedUIError.unexpectedIdentity(mismatch)
        let signInError = SignInError.hostedUI(hostedUIError)
        var dumped = ""
        dump(mismatch, to: &dumped)
        var dumpedError = ""
        dump(hostedUIError, to: &dumpedError)
        let state = HostedUISignInState.error(signInError)

        let outputs: [(String, String)] = [
            ("interpolated", "\(mismatch)"),
            ("reflecting", String(reflecting: mismatch)),
            ("dump", dumped),
            ("dump HostedUIError", dumpedError),
            ("HostedUIError", String(reflecting: hostedUIError)),
            ("SignInError", String(reflecting: signInError)),
            ("EngineAuthError", hostedUIError.engineError.debugDescription),
            ("AuthError", hostedUIError.authError.debugDescription),
            ("state debugDictionary", "\(state.debugDictionary)")
        ]
        for (form, output) in outputs {
            for identity in ["alice@example.com", "bob", "sub-123"] {
                XCTAssertFalse(output.contains(identity), "\(form) leaks \(identity): \(output)")
            }
            XCTAssertTrue(output.contains("notExpectedIdentity"), "\(form): \(output)")
        }
    }

    /// Test which reasons count as a different user
    ///
    /// - Given: Every reason
    /// - When:
    ///    - `isIdentityMismatch` is read
    /// - Then:
    ///    - Only `notExpectedIdentity` and `signedInToAnotherSession` are a different user
    ///
    func testOnlyIdentityReasonsAreIdentityMismatches() {
        let identityReasons = HostedUIIdentityMismatch.Reason.allCases.filter {
            HostedUIIdentityMismatch(reason: $0).isIdentityMismatch
        }
        XCTAssertEqual(identityReasons, [.notExpectedIdentity, .signedInToAnotherSession])
    }

    // MARK: - Helpers

    private static func environment(policy: HostedUIIdentityPolicy?) -> HostedUIEnvironment {
        let configuration = HostedUIConfigurationData(
            clientId: "clientId",
            oauth: OAuthConfigurationData(
                domain: "cognitodomain",
                scopes: ["openid"],
                signInRedirectURI: "myapp://",
                signOutRedirectURI: "myapp://"
            )
        )
        guard let policy else {
            // As every existing caller builds it, without the new trailing parameter.
            return BasicHostedUIEnvironment(
                configuration: configuration,
                hostedUISessionFactory: { MockHostedUISession(result: .success([])) },
                urlSessionFactory: { URLSession.shared },
                randomStringFactory: { MockRandomStringGenerator(mockString: "string", mockUUID: "uuid") }
            )
        }
        return BasicHostedUIEnvironment(
            configuration: configuration,
            hostedUISessionFactory: { MockHostedUISession(result: .success([])) },
            urlSessionFactory: { URLSession.shared },
            randomStringFactory: { MockRandomStringGenerator(mockString: "string", mockUUID: "uuid") },
            identityPolicy: policy
        )
    }
}
