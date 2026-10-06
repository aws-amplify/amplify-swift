//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// SU-3, SU-6, SU-10, SU-13, SU-14: the sign-up calls refuse empty arguments with the plugin's
/// validation errors before anything reaches the engine.
final class SignUpValidationTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: a signed-out session
    /// - When:
    ///    - `signUp`, `confirmSignUp` and `resendSignUpCode` are called with an empty username, and
    ///      `confirmSignUp` with an empty code
    /// - Then:
    ///    - each throws `validation` with the plugin's field, description and suggestion
    ///    - the engine receives nothing
    ///
    func testEmptyArgumentsAreRefusedBeforeTheEngine() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let cases: [(String, AuthPluginValidationErrorString, () async throws -> Any)] = [
            ("signUp", AuthPluginErrorConstants.signUpUsernameError, {
                try await client.signUp(username: "", password: "Password1!")
            }),
            ("passwordless signUp", AuthPluginErrorConstants.signUpUsernameError, {
                try await client.signUp(username: "")
            }),
            ("confirmSignUp username", AuthPluginErrorConstants.signUpUsernameError, {
                try await client.confirmSignUp(for: "", confirmationCode: "123456")
            }),
            ("confirmSignUp code", AuthPluginErrorConstants.confirmSignUpCodeError, {
                try await client.confirmSignUp(for: "carol", confirmationCode: "")
            }),
            ("resendSignUpCode", AuthPluginErrorConstants.resendSignUpCodeUsernameError, {
                try await client.resendSignUpCode(for: "")
            })
        ]

        for (name, expected, call) in cases {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .validation(let field, let description, let suggestion, _) = authError(error) else {
                    return XCTFail("\(name): \(error)")
                }
                XCTAssertEqual(field, expected.field, name)
                XCTAssertEqual(description, expected.errorDescription, name)
                XCTAssertEqual(suggestion, expected.recoverySuggestion, name)
            }
        }
        XCTAssertEqual(engine.accountOperationCalls, [])
    }

    /// The username is checked before the code, as the plugin checks them.
    ///
    /// - Given: a signed-out session
    /// - When:
    ///    - `confirmSignUp` is called with an empty username and an empty code
    /// - Then:
    ///    - it throws `validation` for `username`
    ///
    func testConfirmSignUpChecksTheUsernameFirst() async throws {
        let client = try harness.client(work)

        await assertThrowsAsync({ try await client.confirmSignUp(for: "", confirmationCode: "") }) { error in
            guard case .validation(let field, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(field, "username")
        }
    }

    /// Validation comes before the configuration check, as in the plugin, whose sign-up validates first.
    ///
    /// - Given: a configuration with no user pool
    /// - When:
    ///    - `signUp` is called with an empty username
    /// - Then:
    ///    - it throws `validation`, not `configuration`
    ///
    func testValidationComesBeforeTheConfigurationCheck() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)

        await assertThrowsAsync({ try await client.signUp(username: "") }) { error in
            guard case .validation = authError(error) else {
                return XCTFail("\(error)")
            }
        }
    }
}
