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
    ///    - each throws `validation`: `signUp` and the resend with the plugin's field, description and suggestion;
    ///      `confirmSignUp` with texts that name it and its `confirmationCode` parameter
    ///    - the engine receives nothing
    ///
    func testEmptyArgumentsAreRefusedBeforeTheEngine() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let plugin = { (constant: AuthPluginValidationErrorString) in
            (constant.field, constant.errorDescription, constant.recoverySuggestion)
        }
        let cases: [(String, (String, String, String), () async throws -> Any)] = [
            ("signUp", plugin(AuthPluginErrorConstants.signUpUsernameError), {
                try await client.signUp(username: "", password: "Password1!")
            }),
            ("passwordless signUp", plugin(AuthPluginErrorConstants.signUpUsernameError), {
                try await client.signUp(username: "")
            }),
            ("confirmSignUp username", (
                "username",
                "Username is required to confirmSignUp",
                "Make sure that a valid username is passed for confirmSignUp"
            ), {
                try await client.confirmSignUp(for: "", confirmationCode: "123456")
            }),
            ("confirmSignUp code", (
                "confirmationCode",
                "confirmationCode is required to confirmSignUp",
                "Make sure that a valid confirmationCode is passed for confirmSignUp"
            ), {
                try await client.confirmSignUp(for: "carol", confirmationCode: "")
            }),
            ("resendSignUpCode", plugin(AuthPluginErrorConstants.resendSignUpCodeUsernameError), {
                try await client.resendSignUpCode(for: "")
            })
        ]

        for (name, expected, call) in cases {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .validation(let field, let description, let suggestion, _) = authError(error) else {
                    return XCTFail("\(name): \(error)")
                }
                XCTAssertEqual(field, expected.0, name)
                XCTAssertEqual(description, expected.1, name)
                XCTAssertEqual(suggestion, expected.2, name)
            }
        }
        XCTAssertEqual(engine.accountOperationCalls, [])
    }

    /// The sign-up machine's refusal of a confirmation code names the `confirmationCode` parameter.
    ///
    /// - Given: the sign-up machine's `invalidConfirmationCode` failure
    /// - When:
    ///    - it is mapped
    /// - Then:
    ///    - it is `validation` for `confirmationCode`, with the machine's message and a suggestion naming the parameter
    func testAnInvalidConfirmationCodeNamesTheParameter() {
        let error = AuthClientError(signUp: .invalidConfirmationCode(message: "Invalid code"))

        guard case .validation(let field, let description, let suggestion, _) = error else {
            return XCTFail("\(error)")
        }
        XCTAssertEqual(field, "confirmationCode")
        XCTAssertEqual(description, "Invalid code")
        XCTAssertEqual(suggestion, "Make sure that a valid confirmationCode is passed for confirmSignUp")
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
