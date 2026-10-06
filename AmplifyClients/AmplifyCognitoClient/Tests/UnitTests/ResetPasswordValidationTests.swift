//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The password-reset calls refuse empty arguments with the plugin's validation errors
/// (`AuthResetPasswordRequest.hasError()`, `AuthConfirmResetPasswordRequest.hasError()`) before anything
/// reaches the engine.
final class ResetPasswordValidationTests: XCTestCase {

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
    ///    - `resetPassword` is called with an empty username, and `confirmResetPassword` with an empty
    ///      username, new password or code
    /// - Then:
    ///    - each throws `validation` with the plugin's field, description and suggestion
    ///    - the engine receives nothing
    ///
    func testEmptyArgumentsAreRefusedBeforeTheEngine() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let cases: [(String, AuthPluginValidationErrorString, () async throws -> Any)] = [
            ("resetPassword", AuthPluginErrorConstants.resetPasswordUsernameError, {
                try await client.resetPassword(for: "")
            }),
            ("confirmResetPassword username", AuthPluginErrorConstants.confirmResetPasswordUsernameError, {
                try await client.confirmResetPassword(for: "", with: "NewPassword1!", confirmationCode: "123456")
            }),
            ("confirmResetPassword newPassword", AuthPluginErrorConstants.confirmResetPasswordNewPasswordError, {
                try await client.confirmResetPassword(for: "carol", with: "", confirmationCode: "123456")
            }),
            ("confirmResetPassword code", AuthPluginErrorConstants.confirmResetPasswordCodeError, {
                try await client.confirmResetPassword(for: "carol", with: "NewPassword1!", confirmationCode: "")
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

    /// The arguments are checked in the plugin's order: username, new password, code.
    ///
    /// - Given: a signed-out session
    /// - When:
    ///    - `confirmResetPassword` is called with every argument empty, then with only a username
    /// - Then:
    ///    - the first throws `validation` for `username`, the second for `newPassword`
    ///
    func testConfirmResetPasswordChecksInThePluginsOrder() async throws {
        let client = try harness.client(work)

        await assertThrowsAsync({ try await client.confirmResetPassword(for: "", with: "", confirmationCode: "") }) { error in
            guard case .validation(let field, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(field, "username")
        }
        await assertThrowsAsync({ try await client.confirmResetPassword(for: "carol", with: "", confirmationCode: "") }) { error in
            guard case .validation(let field, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(field, "newPassword")
        }
    }

    /// Validation comes before the configuration check, as in the plugin, whose tasks validate first.
    ///
    /// - Given: a configuration with no user pool
    /// - When:
    ///    - `resetPassword` is called with an empty username, then with a username
    /// - Then:
    ///    - the first throws `validation`, the second `configuration`
    ///
    func testValidationComesBeforeTheConfigurationCheck() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)

        await assertThrowsAsync({ try await client.resetPassword(for: "") }) { error in
            guard case .validation = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await client.resetPassword(for: "carol") }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("\(error)")
            }
        }
    }
}
