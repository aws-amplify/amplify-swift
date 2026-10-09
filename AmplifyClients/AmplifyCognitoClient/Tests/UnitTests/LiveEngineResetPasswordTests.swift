//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's password reset over scripted Cognito: the plugin's `ForgotPassword` and
/// `ConfirmForgotPassword` requests, its result and its error mapping.
final class LiveEngineResetPasswordTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness?.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    // MARK: resetPassword

    /// The request carries what the plugin's does, and the result is the plugin's.
    ///
    /// - Given: Cognito answers `ForgotPassword` with an email delivery
    /// - When:
    ///    - carol's password is reset, with and without client metadata
    /// - Then:
    ///    - each request has the app client, the username, the advanced-security context, and the client
    ///      metadata as given (`[:]` for none, as the plugin sends); no secret hash without a client secret
    ///    - the result is not reset yet, `.confirmResetPasswordWithCode` with the delivery and `[:]`
    ///
    func testResetPasswordSendsThePluginsRequest() async throws {
        let engine = try harness.engine()
        harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) in
            ForgotPasswordOutput(
                codeDeliveryDetails: .init(attributeName: "email", deliveryMedium: .email, destination: "c***@e***")
            )
        }

        let withMetadata = try await engine.resetPassword(username: "carol", clientMetadata: ["app": "test"])
        let without = try await engine.resetPassword(username: "carol", clientMetadata: [:])

        let expected = AuthClientResetPasswordResult(
            isPasswordReset: false,
            nextStep: .confirmResetPasswordWithCode(
                AuthClientCodeDeliveryDetails(destination: .email("c***@e***"), attributeKey: .email),
                [:]
            )
        )
        XCTAssertEqual(withMetadata, expected)
        XCTAssertEqual(without, expected)
        let inputs = harness.cognito.inputs("ForgotPassword", as: ForgotPasswordInput.self)
        XCTAssertEqual(inputs.map(\.username), ["carol", "carol"])
        XCTAssertEqual(inputs.map(\.clientId), Array(repeating: ClientFixtures.userPool.appClientId, count: 2))
        XCTAssertEqual(inputs.map(\.clientMetadata), [["app": "test"], [:]])
        XCTAssertEqual(inputs.map { $0.userContextData?.encodedData != nil }, [true, true])
        // No Pinpoint app is configured, so no analytics endpoint, as the plugin sends without one.
        XCTAssertEqual(inputs.map { $0.analyticsMetadata == nil }, [true, true])
        XCTAssertEqual(inputs.map(\.secretHash), [nil, nil])
        XCTAssertEqual(harness.cognito.operations, ["ForgotPassword", "ForgotPassword"])
    }

    /// The advanced-security context carries the user's ASF device ID, found as the plugin finds it
    /// (`CognitoUserPoolASF.asfDeviceID`): the remembered device's key, else the stored ASF device ID, else a
    /// new one, which is stored and reused.
    ///
    /// - Given: carol has a remembered device record, dave a stored ASF device ID, and erin no record
    /// - When:
    ///    - carol's password is reset and the reset confirmed; dave's is reset; erin's is reset twice
    /// - Then:
    ///    - carol's two requests carry her device key; dave's carries his stored ID
    ///    - erin's two requests carry the same new ID, which is now stored for her
    ///    - each context names its own user
    ///
    func testTheResetRequestsCarryTheUsersASFDeviceID() async throws {
        let store = harness.keychain.deviceStore(for: harness.namespace)
        try store.saveDeviceMetadata(
            DeviceMetadata.metadata(.init(deviceKey: "carol-device-key", deviceGroupKey: "carol-group")),
            for: "carol"
        )
        try store.saveASFDeviceId("dave-asf-id", for: "dave")
        let engine = try harness.engine()
        harness.cognito.always("ForgotPassword") { (_: ForgotPasswordInput) in
            ForgotPasswordOutput(codeDeliveryDetails: .init(deliveryMedium: .email, destination: "c***@e***"))
        }
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) in ConfirmForgotPasswordOutput() }

        _ = try await engine.resetPassword(username: "carol", clientMetadata: [:])
        try await engine.confirmResetPassword(.carol(code: "123456"))
        _ = try await engine.resetPassword(username: "dave", clientMetadata: [:])
        _ = try await engine.resetPassword(username: "erin", clientMetadata: [:])
        _ = try await engine.resetPassword(username: "erin", clientMetadata: [:])

        let resets = try harness.cognito.inputs("ForgotPassword", as: ForgotPasswordInput.self)
            .map { try Self.advancedSecurityContext($0.userContextData) }
        let confirm = try harness.cognito.inputs("ConfirmForgotPassword", as: ConfirmForgotPasswordInput.self)
            .map { try Self.advancedSecurityContext($0.userContextData) }
        XCTAssertEqual(resets.map(\.username), ["carol", "dave", "erin", "erin"])
        XCTAssertEqual(resets[0].deviceId, "carol-device-key")
        XCTAssertEqual(confirm.map(\.deviceId), ["carol-device-key"])
        XCTAssertEqual(resets[1].deviceId, "dave-asf-id")
        let erinId = try XCTUnwrap(resets[2].deviceId)
        XCTAssertEqual(resets[3].deviceId, erinId)
        XCTAssertFalse(["carol-device-key", "dave-asf-id"].contains(erinId))
        XCTAssertEqual(try store.asfDeviceId(for: "erin"), .value(erinId))
    }

    /// With a client secret, both reset requests carry the plugin's secret hash for the username.
    ///
    /// - Given: an app client with a secret; Cognito answers both reset calls
    /// - When:
    ///    - carol's password is reset, then the reset is confirmed
    /// - Then:
    ///    - both requests carry `ClientSecretHelper`'s hash for carol
    ///
    func testTheResetRequestsCarryTheSecretHash() async throws {
        let userPool = AuthClientConfiguration.UserPool(
            poolId: StorageFixtures.userPoolId,
            appClientId: "app-client-1",
            region: "us-east-1",
            appClientSecret: "app-client-secret"
        )
        harness = LiveEngineHarness(configuration: ClientFixtures.make(userPool: userPool, identityPool: nil))
        let engine = try harness.engine()
        harness.cognito.once("ForgotPassword") { (_: ForgotPasswordInput) in
            ForgotPasswordOutput(codeDeliveryDetails: .init(deliveryMedium: .email, destination: "c***@e***"))
        }
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) in ConfirmForgotPasswordOutput() }

        _ = try await engine.resetPassword(username: "carol", clientMetadata: [:])
        try await engine.confirmResetPassword(.carol(code: "123456"))

        let configuration = try XCTUnwrap(AuthConfiguration(client: harness.configuration).getUserPoolConfiguration())
        let expected = try XCTUnwrap(ClientSecretHelper.calculateSecretHash(username: "carol", userPoolConfiguration: configuration))
        XCTAssertEqual(harness.cognito.inputs("ForgotPassword", as: ForgotPasswordInput.self).map(\.secretHash), [expected])
        XCTAssertEqual(
            harness.cognito.inputs("ConfirmForgotPassword", as: ConfirmForgotPasswordInput.self).map(\.secretHash),
            [expected]
        )
    }

    /// An answer without delivery details is the plugin's `unknown`; Cognito's refusals are mapped.
    ///
    /// - Given: Cognito answers `ForgotPassword` with no details, then `UserNotFoundException`, then
    ///   `LimitExceededException`
    /// - When:
    ///    - the password is reset three times
    /// - Then:
    ///    - the first throws `.unknown` with the plugin's "Unexpected error occurred with message: Unable to get Auth code delivery details"
    ///    - the second `.service(.userNotFound)`, the third `.service(.limitExceeded)`
    ///
    func testResetPasswordFailures() async throws {
        let engine = try harness.engine()
        harness.cognito.once("ForgotPassword") { (_: ForgotPasswordInput) in ForgotPasswordOutput() }
        harness.cognito.once("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in
            throw UserNotFoundException(message: "Username/client id combination not found.")
        }
        harness.cognito.once("ForgotPassword") { (_: ForgotPasswordInput) -> ForgotPasswordOutput in
            throw LimitExceededException(message: "Attempt limit exceeded, please try after some time.")
        }

        await assertThrowsAsync({ try await engine.resetPassword(username: "carol", clientMetadata: [:]) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Unexpected error occurred with message: Unable to get Auth code delivery details")
        }
        await assertThrowsAsync({ try await engine.resetPassword(username: "carol", clientMetadata: [:]) }) { error in
            guard case .service(.userNotFound?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await engine.resetPassword(username: "carol", clientMetadata: [:]) }) { error in
            guard case .service(.limitExceeded?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["ForgotPassword", "ForgotPassword", "ForgotPassword"])
    }

    // MARK: confirmResetPassword

    /// The confirmation carries what the plugin's does.
    ///
    /// - Given: Cognito answers `ConfirmForgotPassword`
    /// - When:
    ///    - carol's reset is confirmed with client metadata, then without
    /// - Then:
    ///    - each request has the app client, username, code, new password, the advanced-security context
    ///      and the client metadata as given (`[:]` for none)
    ///
    func testConfirmResetPasswordSendsThePluginsRequest() async throws {
        let engine = try harness.engine()
        harness.cognito.always("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) in ConfirmForgotPasswordOutput() }

        try await engine.confirmResetPassword(.carol(code: "123456", clientMetadata: ["app": "test"]))
        try await engine.confirmResetPassword(.carol(code: "654321"))

        let inputs = harness.cognito.inputs("ConfirmForgotPassword", as: ConfirmForgotPasswordInput.self)
        XCTAssertEqual(inputs.map(\.username), ["carol", "carol"])
        XCTAssertEqual(inputs.map(\.clientId), Array(repeating: ClientFixtures.userPool.appClientId, count: 2))
        XCTAssertEqual(inputs.map(\.confirmationCode), ["123456", "654321"])
        XCTAssertEqual(inputs.map(\.password), ["NewPassword1!", "NewPassword1!"])
        XCTAssertEqual(inputs.map(\.clientMetadata), [["app": "test"], [:]])
        XCTAssertEqual(inputs.map { $0.userContextData?.encodedData != nil }, [true, true])
        // No Pinpoint app is configured, so no analytics endpoint, as the plugin sends without one.
        XCTAssertEqual(inputs.map { $0.analyticsMetadata == nil }, [true, true])
        XCTAssertEqual(harness.cognito.operations, ["ConfirmForgotPassword", "ConfirmForgotPassword"])
    }

    /// Cognito's refusals of a confirmation are mapped as the plugin maps them.
    ///
    /// - Given: Cognito answers `ConfirmForgotPassword` with `CodeMismatchException`, `ExpiredCodeException`,
    ///   then `InvalidPasswordException`
    /// - When:
    ///    - the reset is confirmed three times
    /// - Then:
    ///    - `.service(.codeMismatch)`, `.service(.codeExpired)`, `.service(.invalidPassword)`
    ///
    func testConfirmResetPasswordFailures() async throws {
        let engine = try harness.engine()
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) -> ConfirmForgotPasswordOutput in
            throw CodeMismatchException(message: "Invalid verification code provided, please try again.")
        }
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) -> ConfirmForgotPasswordOutput in
            throw ExpiredCodeException(message: "Invalid code provided, please request a code again.")
        }
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) -> ConfirmForgotPasswordOutput in
            throw InvalidPasswordException(message: "Password does not conform to policy.")
        }

        for expected in [AuthClientServiceErrorCode.codeMismatch, .codeExpired, .invalidPassword] {
            await assertThrowsAsync({ try await engine.confirmResetPassword(.carol(code: "123456")) }) { error in
                guard case .service(let code, _, _, _) = authError(error) else {
                    return XCTFail("\(expected): \(error)")
                }
                XCTAssertEqual(code, expected)
            }
        }
        XCTAssertEqual(harness.cognito.operations, Array(repeating: "ConfirmForgotPassword", count: 3))
    }

    // MARK: Configuration

    /// Without a user pool, both reset calls throw `configuration` before any request.
    ///
    /// - Given: an engine over an identity-pool-only configuration
    /// - When:
    ///    - each reset call is made
    /// - Then:
    ///    - each throws `configuration`, and no request is made
    ///
    func testResetPasswordNeedsAUserPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let engine = try harness.engine()
        let calls: [() async throws -> Any] = [
            { try await engine.resetPassword(username: "carol", clientMetadata: [:]) },
            { try await engine.confirmResetPassword(.carol(code: "123456")) }
        ]
        for call in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .configuration = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Through the public API

    /// A reset over the live engine runs on a signed-in session too, and changes nothing in it.
    ///
    /// - Given: a client over the live engine with alice signed in; Cognito answers both reset calls
    /// - When:
    ///    - carol's password is reset and the reset confirmed through the public API
    /// - Then:
    ///    - both succeed with the plugin's result
    ///    - alice is still signed in, her stored record is unchanged, and no token was refreshed
    ///
    func testAResetLeavesASignedInSessionAsItIs() async throws {
        let clientHarness = ClientHarness()
        let base = clientHarness.dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        let work = ClientFixtures.id("work")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        harness.scriptSRP("alice")
        harness.scriptIdentityPool()
        harness.cognito.once("ForgotPassword") { (_: ForgotPasswordInput) in
            ForgotPasswordOutput(codeDeliveryDetails: .init(deliveryMedium: .email, destination: "c***@e***"))
        }
        harness.cognito.once("ConfirmForgotPassword") { (_: ConfirmForgotPasswordInput) in ConfirmForgotPasswordOutput() }
        _ = try await client.signIn(username: "alice", password: "password")
        let before = try clientHarness.storedRecord(work)
        harness.cognito.clearCalls()

        let result = try await client.resetPassword(for: "carol")
        try await client.confirmResetPassword(for: "carol", with: "NewPassword1!", confirmationCode: "123456")

        XCTAssertEqual(result.nextStep, .confirmResetPasswordWithCode(.init(destination: .email("c***@e***")), [:]))
        XCTAssertFalse(result.isPasswordReset)
        XCTAssertEqual(harness.cognito.operations, ["ForgotPassword", "ConfirmForgotPassword"])
        let user = try await client.getCurrentUser()
        XCTAssertEqual(user.username, "alice")
        XCTAssertEqual(try clientHarness.storedRecord(work), before)
    }

    // MARK: Helpers

    /// The username and ASF device ID in an encoded advanced-security context: base64 JSON whose `payload` is
    /// JSON with `username` and `contextData` (`CognitoUserPoolASF.userContextData`).
    private static func advancedSecurityContext(
        _ context: CognitoIdentityProviderClientTypes.UserContextDataType?
    ) throws -> (username: String?, deviceId: String?) {
        let encoded = try XCTUnwrap(context?.encodedData, "no advanced-security context")
        let outer = try XCTUnwrap(Data(base64Encoded: encoded))
        let result = try XCTUnwrap(JSONSerialization.jsonObject(with: outer) as? [String: Any])
        let payload = try XCTUnwrap(result["payload"] as? String)
        let inner = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(payload.utf8)) as? [String: Any])
        let contextData = inner["contextData"] as? [String: String]
        return (inner["username"] as? String, contextData?[CognitoUserPoolASF.deviceIdKey])
    }
}

extension EngineConfirmResetPasswordRequest {

    static func carol(code: String, clientMetadata: [String: String] = [:]) -> EngineConfirmResetPasswordRequest {
        EngineConfirmResetPasswordRequest(
            username: "carol",
            newPassword: "NewPassword1!",
            confirmationCode: code,
            clientMetadata: clientMetadata
        )
    }
}
