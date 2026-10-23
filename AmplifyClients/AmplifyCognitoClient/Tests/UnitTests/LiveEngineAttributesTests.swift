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

/// The live engine's user-attribute operations and password change over scripted Cognito: the
/// plugin's requests with the payload's access token as it is, its results and its error mapping.
final class LiveEngineAttributesTests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness(configuration: ClientFixtures.userPoolOnlyConfiguration)
    }

    override func tearDown() {
        harness?.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    // MARK: fetchUserAttributes

    /// The fetch sends `GetUser` with the payload's access token, and maps every named attribute.
    ///
    /// - Given: alice's payload; Cognito answers `GetUser` with a standard, a custom and an unknown
    ///   attribute, and one without a value
    /// - When:
    ///    - the attributes are fetched
    /// - Then:
    ///    - one `GetUser` with the payload's access token
    ///    - the attributes by the client's keys, in Cognito's order, without the one with no value
    ///
    func testFetchUserAttributesSendsTheAccessToken() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("GetUser") { (_: GetUserInput) in
            GetUserOutput(
                userAttributes: [
                    .init(name: "email", value: "alice@example.com"),
                    .init(name: "custom:team", value: "blue"),
                    .init(name: "zoneinfo_extra", value: "x"),
                    .init(name: "name", value: nil)
                ],
                username: "alice"
            )
        }

        let attributes = try await engine.fetchUserAttributes(payload)

        XCTAssertEqual(attributes, [
            AuthClientUserAttribute(.email, value: "alice@example.com"),
            AuthClientUserAttribute(.custom("team"), value: "blue"),
            AuthClientUserAttribute(.unknown("zoneinfo_extra"), value: "x")
        ])
        XCTAssertEqual(harness.cognito.inputs("GetUser", as: GetUserInput.self).map(\.accessToken), [try accessToken(payload)])
        XCTAssertEqual(harness.cognito.operations, ["GetUser"])
    }

    /// An answer without attributes is the plugin's `unknown`; a refusal is mapped.
    ///
    /// - Given: Cognito answers `GetUser` with no attributes, then `NotAuthorizedException`
    /// - When:
    ///    - the attributes are fetched twice
    /// - Then:
    ///    - the first throws `.unknown` with the plugin's message, the second `.notAuthorized`
    ///
    func testFetchUserAttributesFailures() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("GetUser") { (_: GetUserInput) in GetUserOutput(username: "alice") }
        harness.cognito.once("GetUser") { (_: GetUserInput) -> GetUserOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Access Token has been revoked")
        }

        await assertThrowsAsync({ try await engine.fetchUserAttributes(payload) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Unexpected error occurred with message: Unable to get Auth code delivery details")
        }
        await assertThrowsAsync({ try await engine.fetchUserAttributes(payload) }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetUser", "GetUser"])
    }

    // MARK: updateUserAttributes

    /// The update sends the plugin's request, and each attribute's result is the plugin's.
    ///
    /// - Given: alice's payload; Cognito answers `UpdateUserAttributes` with a code sent for `email`
    /// - When:
    ///    - `email`, `name` and `custom:team` are updated with client metadata, then `name` alone without
    /// - Then:
    ///    - each request has the access token, the attributes by Cognito name, and the client metadata as
    ///      given (`[:]` for none, as the plugin sends)
    ///    - `email` is not updated yet, `.confirmAttributeWithCode(details, nil)`; the others are updated,
    ///      `.done`
    ///
    func testUpdateUserAttributesSendsThePluginsRequest() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("UpdateUserAttributes") { (_: UpdateUserAttributesInput) in
            UpdateUserAttributesOutput(codeDeliveryDetailsList: [
                .init(attributeName: "email", deliveryMedium: .email, destination: "a***@e***"),
                .init(deliveryMedium: .email, destination: "unnamed")
            ])
        }
        harness.cognito.once("UpdateUserAttributes") { (_: UpdateUserAttributesInput) in UpdateUserAttributesOutput() }

        let results = try await engine.updateUserAttributes(
            payload,
            attributes: [
                AuthClientUserAttribute(.email, value: "new@example.com"),
                AuthClientUserAttribute(.name, value: "Alice"),
                AuthClientUserAttribute(.custom("team"), value: "blue")
            ],
            clientMetadata: ["app": "test"]
        )
        let second = try await engine.updateUserAttributes(
            payload,
            attributes: [AuthClientUserAttribute(.name, value: "Alice")],
            clientMetadata: [:]
        )

        let emailDetails = AuthClientCodeDeliveryDetails(destination: .email("a***@e***"), attributeKey: .email)
        XCTAssertEqual(results, [
            .email: AuthClientUpdateAttributeResult(isUpdated: false, nextStep: .confirmAttributeWithCode(emailDetails, nil)),
            .name: AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done),
            .custom("team"): AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)
        ])
        XCTAssertEqual(second, [.name: AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)])
        let inputs = harness.cognito.inputs("UpdateUserAttributes", as: UpdateUserAttributesInput.self)
        let token = try accessToken(payload)
        XCTAssertEqual(inputs.map(\.accessToken), [token, token])
        XCTAssertEqual(inputs.map(\.clientMetadata), [["app": "test"], [:]])
        XCTAssertEqual(inputs.first?.userAttributes?.map(\.name), ["email", "name", "custom:team"])
        XCTAssertEqual(inputs.first?.userAttributes?.map(\.value), ["new@example.com", "Alice", "blue"])
        XCTAssertEqual(harness.cognito.operations, ["UpdateUserAttributes", "UpdateUserAttributes"])
    }

    /// Cognito's refusal of an update is mapped.
    ///
    /// - Given: Cognito answers `UpdateUserAttributes` with `AliasExistsException`
    /// - When:
    ///    - the email is updated
    /// - Then:
    ///    - it throws `.service(.aliasExists)`
    ///
    func testUpdateUserAttributesFailure() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("UpdateUserAttributes") { (_: UpdateUserAttributesInput) -> UpdateUserAttributesOutput in
            throw AliasExistsException(message: "An account with the given email already exists.")
        }

        await assertThrowsAsync({
            try await engine.updateUserAttributes(payload, attributes: [.init(.email, value: "b@example.com")], clientMetadata: [:])
        }) { error in
            guard case .service(.aliasExists?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["UpdateUserAttributes"])
    }

    // MARK: sendVerificationCode

    /// The request carries the attribute's Cognito name and the client metadata as given.
    ///
    /// - Given: alice's payload; Cognito answers `GetUserAttributeVerificationCode` with an email delivery,
    ///   then with no details, then `LimitExceededException`
    /// - When:
    ///    - a code is sent for `email` with client metadata, then twice without
    /// - Then:
    ///    - the first returns the delivery; the second throws the plugin's `unknown`; the third
    ///      `.service(.limitExceeded)`
    ///    - each request has the access token, `email`, and the client metadata (`[:]` for none)
    ///
    func testSendVerificationCode() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("GetUserAttributeVerificationCode") { (_: GetUserAttributeVerificationCodeInput) in
            GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(attributeName: "email", deliveryMedium: .email, destination: "a***@e***")
            )
        }
        harness.cognito.once("GetUserAttributeVerificationCode") { (_: GetUserAttributeVerificationCodeInput) in
            GetUserAttributeVerificationCodeOutput()
        }
        harness.cognito.once("GetUserAttributeVerificationCode") { (_: GetUserAttributeVerificationCodeInput) -> GetUserAttributeVerificationCodeOutput in
            throw LimitExceededException(message: "Attempt limit exceeded, please try after some time.")
        }

        let details = try await engine.sendVerificationCode(payload, attributeKey: .email, clientMetadata: ["app": "test"])
        await assertThrowsAsync({ try await engine.sendVerificationCode(payload, attributeKey: .email, clientMetadata: [:]) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Unexpected error occurred with message: Unable to get Auth code delivery details")
        }
        await assertThrowsAsync({ try await engine.sendVerificationCode(payload, attributeKey: .email, clientMetadata: [:]) }) { error in
            guard case .service(.limitExceeded?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        XCTAssertEqual(details, AuthClientCodeDeliveryDetails(destination: .email("a***@e***"), attributeKey: .email))
        let inputs = harness.cognito.inputs("GetUserAttributeVerificationCode", as: GetUserAttributeVerificationCodeInput.self)
        let token = try accessToken(payload)
        XCTAssertEqual(inputs.map(\.accessToken), [token, token, token])
        XCTAssertEqual(inputs.map(\.attributeName), ["email", "email", "email"])
        XCTAssertEqual(inputs.map(\.clientMetadata), [["app": "test"], [:], [:]])
    }

    // MARK: confirmUserAttribute

    /// The confirmation carries the attribute's Cognito name and the code; a wrong code is mapped.
    ///
    /// - Given: alice's payload; Cognito answers `VerifyUserAttribute`, then `CodeMismatchException`
    /// - When:
    ///    - `email` is confirmed twice
    /// - Then:
    ///    - the first succeeds; the second throws `.service(.codeMismatch)`
    ///    - each request has the access token, `email` and the code
    ///
    func testConfirmUserAttribute() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("VerifyUserAttribute") { (_: VerifyUserAttributeInput) in VerifyUserAttributeOutput() }
        harness.cognito.once("VerifyUserAttribute") { (_: VerifyUserAttributeInput) -> VerifyUserAttributeOutput in
            throw CodeMismatchException(message: "Invalid verification code provided, please try again.")
        }

        try await engine.confirmUserAttribute(payload, attributeKey: .email, confirmationCode: "123456")
        await assertThrowsAsync({ try await engine.confirmUserAttribute(payload, attributeKey: .email, confirmationCode: "000000") }) { error in
            guard case .service(.codeMismatch?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        let inputs = harness.cognito.inputs("VerifyUserAttribute", as: VerifyUserAttributeInput.self)
        let token = try accessToken(payload)
        XCTAssertEqual(inputs.map(\.accessToken), [token, token])
        XCTAssertEqual(inputs.map(\.attributeName), ["email", "email"])
        XCTAssertEqual(inputs.map(\.code), ["123456", "000000"])
    }

    // MARK: changePassword

    /// The change carries both passwords; a wrong old password is `notAuthorized`, a weak new one
    /// `invalidPassword`.
    ///
    /// - Given: alice's payload; Cognito answers `ChangePassword`, then `NotAuthorizedException`, then
    ///   `InvalidPasswordException`
    /// - When:
    ///    - the password is changed three times
    /// - Then:
    ///    - the first succeeds; the second throws `.notAuthorized`; the third `.service(.invalidPassword)`
    ///    - each request has the access token and both passwords
    ///
    func testChangePassword() async throws {
        let (engine, payload) = try await signedInEngine()
        harness.cognito.once("ChangePassword") { (_: ChangePasswordInput) in ChangePasswordOutput() }
        harness.cognito.once("ChangePassword") { (_: ChangePasswordInput) -> ChangePasswordOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Incorrect username or password.")
        }
        harness.cognito.once("ChangePassword") { (_: ChangePasswordInput) -> ChangePasswordOutput in
            throw InvalidPasswordException(message: "Password does not conform to policy.")
        }

        try await engine.changePassword(payload, oldPassword: "Old-password1", newPassword: "New-password1")
        await assertThrowsAsync({ try await engine.changePassword(payload, oldPassword: "wrong", newPassword: "New-password1") }) { error in
            guard case .notAuthorized = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await engine.changePassword(payload, oldPassword: "Old-password1", newPassword: "weak") }) { error in
            guard case .service(.invalidPassword?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        let inputs = harness.cognito.inputs("ChangePassword", as: ChangePasswordInput.self)
        let token = try accessToken(payload)
        XCTAssertEqual(inputs.map(\.accessToken), [token, token, token])
        XCTAssertEqual(inputs.map(\.previousPassword), ["Old-password1", "wrong", "Old-password1"])
        XCTAssertEqual(inputs.map(\.proposedPassword), ["New-password1", "New-password1", "weak"])
    }

    // MARK: The payload as it is

    /// The engine never refreshes: an expired access token is sent as it is (the core refreshes first).
    ///
    /// - Given: a payload whose tokens have expired
    /// - When:
    ///    - each of the five operations is called with it
    /// - Then:
    ///    - each request carries the expired token, and no refresh is made
    ///
    func testTheOperationsNeverRefresh() async throws {
        let engine = try harness.engine()
        let expired = Date(timeIntervalSince1970: 1_700_000_600)
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in LiveEngineFixtures.passwordVerifier("alice") }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            RespondToAuthChallengeOutput(
                authenticationResult: .init(
                    accessToken: LiveEngineFixtures.jwt("alice", use: "access", expiry: expired),
                    expiresIn: 3_600,
                    idToken: LiveEngineFixtures.jwt("alice", use: "id", expiry: expired),
                    refreshToken: "refresh-alice",
                    tokenType: "Bearer"
                ),
                challengeParameters: [:]
            )
        }
        guard case .done(let payload) = try await engine.signIn(.srp("alice"), current: nil) else {
            return XCTFail("the scripted sign-in did not finish")
        }
        XCTAssertTrue(try engine.needsRefresh(payload, at: Date()))
        scriptPlainSuccesses()
        harness.cognito.clearCalls()

        _ = try await engine.fetchUserAttributes(payload)
        _ = try await engine.updateUserAttributes(payload, attributes: [.init(.name, value: "A")], clientMetadata: [:])
        _ = try await engine.sendVerificationCode(payload, attributeKey: .email, clientMetadata: [:])
        try await engine.confirmUserAttribute(payload, attributeKey: .email, confirmationCode: "123456")
        try await engine.changePassword(payload, oldPassword: "a", newPassword: "b")

        XCTAssertEqual(harness.cognito.operations, [
            "GetUser", "UpdateUserAttributes", "GetUserAttributeVerificationCode", "VerifyUserAttribute", "ChangePassword"
        ])
        let token = try accessToken(payload)
        XCTAssertEqual(accessTokensOfTheFiveRequests(), Array(repeating: token as String?, count: 5))
    }

    /// A payload without user-pool tokens is refused before any request (the seam's contract; the core
    /// refuses it first).
    ///
    /// - Given: an empty payload
    /// - When:
    ///    - each operation is called with it
    /// - Then:
    ///    - each throws `SessionEngineError.notSignedIn`, and no request is made
    ///
    func testAPayloadWithoutTokensIsRefused() async throws {
        let engine = try harness.engine()
        let payload = try CredentialSlot.encode(.noCredentials)
        for call in operations(engine, payload) {
            await assertThrowsAsync({ try await call() }) { error in
                guard case SessionEngineError.notSignedIn = error else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// Without a user pool, every operation throws `configuration` before any request.
    ///
    /// - Given: an engine over an identity-pool-only configuration
    /// - When:
    ///    - each operation is called
    /// - Then:
    ///    - each throws `configuration`, and no request is made
    ///
    func testTheOperationsNeedAUserPool() async throws {
        harness = LiveEngineHarness(configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let engine = try harness.engine()
        let payload = try CredentialSlot.encode(.noCredentials)
        for call in operations(engine, payload) {
            await assertThrowsAsync({ try await call() }) { error in
                guard case .configuration = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    // MARK: Through the public API

    /// The public calls over the live engine use the session's own access token, never refresh a valid one,
    /// and change nothing in the session.
    ///
    /// - Given: two clients over the live engine, alice signed in on `work` and bob on `home`
    /// - When:
    ///    - `work` fetches, updates one attribute, sends and confirms a code, and changes the password
    /// - Then:
    ///    - every request carries alice's access token, and no refresh is made
    ///    - `update(userAttribute:)` returns the result for its key
    ///    - alice is still signed in on `work` with the same record; `home` is unchanged
    ///
    func testTheOperationsThroughThePublicAPI() async throws {
        harness = LiveEngineHarness()
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
        let home = ClientFixtures.id("home")
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: work),
            dependencies: dependencies
        )
        let other = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: home),
            dependencies: dependencies
        )
        harness.scriptIdentityPool()
        harness.scriptSRP("alice")
        _ = try await client.signIn(username: "alice", password: "password")
        harness.scriptSRP("bob")
        _ = try await other.signIn(username: "bob", password: "password")
        let workRecord = try clientHarness.storedRecord(work)
        let homeRecord = try clientHarness.storedRecord(home)
        let aliceToken = try await client.fetchAuthSession().userPoolTokensResult.get().accessToken
        scriptPlainSuccesses()
        harness.cognito.once("UpdateUserAttributes") { (_: UpdateUserAttributesInput) in
            UpdateUserAttributesOutput(codeDeliveryDetailsList: [
                .init(attributeName: "email", deliveryMedium: .email, destination: "a***@e***")
            ])
        }
        harness.cognito.clearCalls()

        let attributes = try await client.fetchUserAttributes()
        let updated = try await client.update(userAttribute: .init(.email, value: "new@example.com"))
        let details = try await client.sendVerificationCode(forUserAttributeKey: .email)
        try await client.confirm(userAttribute: .email, confirmationCode: "123456")
        try await client.update(oldPassword: "password", to: "New-password1")

        XCTAssertEqual(attributes, [AuthClientUserAttribute(.email, value: "alice@example.com")])
        XCTAssertEqual(updated, AuthClientUpdateAttributeResult(
            isUpdated: false,
            nextStep: .confirmAttributeWithCode(.init(destination: .email("a***@e***"), attributeKey: .email), nil)
        ))
        XCTAssertEqual(details.attributeKey, .email)
        XCTAssertEqual(harness.cognito.operations, [
            "GetUser", "UpdateUserAttributes", "GetUserAttributeVerificationCode", "VerifyUserAttribute", "ChangePassword"
        ])
        XCTAssertEqual(accessTokensOfTheFiveRequests(), Array(repeating: aliceToken as String?, count: 5))
        let user = try await client.getCurrentUser()
        XCTAssertEqual(user.username, "alice")
        XCTAssertEqual(try clientHarness.storedRecord(work), workRecord)
        XCTAssertEqual(try clientHarness.storedRecord(home), homeRecord)
    }

    // MARK: Helpers

    /// An engine with alice signed in on the user pool, and her payload; the sign-in's calls are cleared.
    private func signedInEngine() async throws -> (LiveSessionEngine, Data) {
        let engine = try harness.engine()
        harness.scriptSRP("alice")
        guard case .done(let payload) = try await engine.signIn(.srp("alice"), current: nil) else {
            throw FixtureError(description: "the scripted sign-in did not finish")
        }
        harness.cognito.clearCalls()
        return (engine, payload)
    }

    /// The access token of each of the five operations' requests, in the operations' order.
    private func accessTokensOfTheFiveRequests() -> [String?] {
        let cognito = harness.cognito
        return cognito.inputs("GetUser", as: GetUserInput.self).map(\.accessToken)
            + cognito.inputs("UpdateUserAttributes", as: UpdateUserAttributesInput.self).map(\.accessToken)
            + cognito.inputs("GetUserAttributeVerificationCode", as: GetUserAttributeVerificationCodeInput.self).map(\.accessToken)
            + cognito.inputs("VerifyUserAttribute", as: VerifyUserAttributeInput.self).map(\.accessToken)
            + cognito.inputs("ChangePassword", as: ChangePasswordInput.self).map(\.accessToken)
    }

    private func accessToken(_ payload: Data) throws -> String {
        try XCTUnwrap(LiveSessionEngine.credentials(in: payload).userPoolTokens?.accessToken)
    }

    /// Plain successes for the five operations.
    private func scriptPlainSuccesses() {
        harness.cognito.always("GetUser") { (_: GetUserInput) in
            GetUserOutput(userAttributes: [.init(name: "email", value: "alice@example.com")], username: "alice")
        }
        harness.cognito.always("UpdateUserAttributes") { (_: UpdateUserAttributesInput) in UpdateUserAttributesOutput() }
        harness.cognito.always("GetUserAttributeVerificationCode") { (_: GetUserAttributeVerificationCodeInput) in
            GetUserAttributeVerificationCodeOutput(
                codeDeliveryDetails: .init(attributeName: "email", deliveryMedium: .email, destination: "a***@e***")
            )
        }
        harness.cognito.always("VerifyUserAttribute") { (_: VerifyUserAttributeInput) in VerifyUserAttributeOutput() }
        harness.cognito.always("ChangePassword") { (_: ChangePasswordInput) in ChangePasswordOutput() }
    }

    private func operations(_ engine: LiveSessionEngine, _ payload: Data) -> [() async throws -> Any] {
        [
            { try await engine.fetchUserAttributes(payload) },
            { try await engine.updateUserAttributes(payload, attributes: [.init(.name, value: "A")], clientMetadata: [:]) },
            { try await engine.sendVerificationCode(payload, attributeKey: .email, clientMetadata: [:]) },
            { try await engine.confirmUserAttribute(payload, attributeKey: .email, confirmationCode: "1") },
            { try await engine.changePassword(payload, oldPassword: "a", newPassword: "b") }
        ]
    }
}
