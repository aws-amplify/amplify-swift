//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// Every facade method beyond sign-in and the session operations reaches its seam method once, with
/// its arguments mapped, on its own session's engine and with its own session's payload; and the core's
/// routes refuse what they must before the engine is called.
final class AccountOperationRoutingTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: User-pool operations

    /// - Given: two sessions, both signed out
    /// - When: each sign-up and password-reset call is made on `work`
    /// - Then:
    ///    - `work`'s engine receives each call once, in order, with the options mapped (attribute keys to
    ///      Cognito's names), and returns its result; `home`'s engine receives nothing
    func testUserPoolOperationsRouteToTheirSessionsEngine() async throws {
        let client = try harness.client(work)
        _ = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let other = try XCTUnwrap(harness.engine(for: home))
        let metadata = ["app": "test"]

        let signUp = try await client.signUp(
            username: "carol",
            password: "Password1!",
            options: .init(
                userAttributes: [.init(.email, value: "carol@example.com"), .init(.custom("team"), value: "blue")],
                validationData: ["v": "1"],
                clientMetadata: metadata
            )
        )
        let confirm = try await client.confirmSignUp(
            for: "carol",
            confirmationCode: "123456",
            options: .init(clientMetadata: metadata, forceAliasCreation: true)
        )
        let resend = try await client.resendSignUpCode(for: "carol", options: .init(clientMetadata: metadata))
        let reset = try await client.resetPassword(for: "carol", options: .init(clientMetadata: metadata))
        try await client.confirmResetPassword(
            for: "carol",
            with: "NewPassword1!",
            confirmationCode: "654321",
            options: .init(clientMetadata: metadata)
        )

        XCTAssertEqual(engine.accountOperationCalls, [
            .signUp(EngineSignUpRequest(
                username: "carol",
                password: "Password1!",
                userAttributes: ["email": "carol@example.com", "custom:team": "blue"],
                validationData: ["v": "1"],
                clientMetadata: metadata
            )),
            .confirmSignUp(EngineConfirmSignUpRequest(
                username: "carol",
                confirmationCode: "123456",
                clientMetadata: metadata,
                forceAliasCreation: true
            )),
            .resendSignUpCode(username: "carol", clientMetadata: metadata),
            .resetPassword(username: "carol", clientMetadata: metadata),
            .confirmResetPassword(EngineConfirmResetPasswordRequest(
                username: "carol",
                newPassword: "NewPassword1!",
                confirmationCode: "654321",
                clientMetadata: metadata
            ))
        ])
        XCTAssertEqual(signUp, AuthClientSignUpResult(.done, userId: "sub-carol"))
        XCTAssertEqual(confirm, AuthClientSignUpResult(.done, userId: "sub-carol"))
        XCTAssertEqual(resend, FakeSessionEngine.delivery)
        XCTAssertEqual(reset.nextStep, .confirmResetPasswordWithCode(FakeSessionEngine.delivery, nil))
        XCTAssertEqual(other.accountOperationCalls, [])
    }

    /// Sign-up acts on a username, so it runs on a signed-in session too, as with the plugin, and changes
    /// nothing in it.
    ///
    /// - Given: a signed-in session
    /// - When: `signUp` is called
    /// - Then:
    ///    - the engine receives it without a payload, and the session's record is not written
    func testUserPoolOperationsIgnoreTheSessionsState() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await client.signUp(username: "carol")

        XCTAssertEqual(engine.accountOperationCalls.map(\.operation), [.signUp])
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: a configuration with no user pool
    /// - When: a user-pool or signed-in operation is called
    /// - Then:
    ///    - it throws `configuration`, and the engine receives nothing
    func testOperationsNeedAUserPool() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.identityPoolOnlyConfiguration)
        let engine = try XCTUnwrap(harness.engine(for: work))

        await assertThrowsAsync({ try await client.signUp(username: "carol") }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await client.fetchDevices() }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await client.autoSignIn() }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(engine.accountOperationCalls, [])
    }

    // MARK: Signed-in operations

    /// - Given: `work` signed in as alice and `home` as bob
    /// - When: every signed-in call is made on `work`, then one on `home`
    /// - Then:
    ///    - `work`'s engine receives each once, in order, with alice's payload and the call's arguments;
    ///      `home`'s engine receives only its own call, with bob's payload; nothing writes a record
    func testSignedInOperationsRouteWithTheirSessionsPayload() async throws {
        let alice = FakePayload.signedIn("alice")
        let bob = FakePayload.signedIn("bob")
        try harness.signIn(work, alice)
        try harness.signIn(home, bob)
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let other = try XCTUnwrap(harness.engine(for: home))
        let metadata = ["app": "test"]
        let email = AuthClientUserAttribute(.email, value: "alice@example.org")
        let name = AuthClientUserAttribute(.name, value: "Alice")
        let device = AuthClientDevice(id: "device-2", name: "iPad")

        let attributes = try await client.fetchUserAttributes()
        let single = try await client.update(userAttribute: email, options: .init(clientMetadata: metadata))
        let several = try await client.update(userAttributes: [email, name], options: .init(clientMetadata: metadata))
        let delivery = try await client.sendVerificationCode(forUserAttributeKey: .email, options: .init(clientMetadata: metadata))
        try await client.confirm(userAttribute: .email, confirmationCode: "111111")
        try await client.update(oldPassword: "old", to: "new")
        let totp = try await client.setUpTOTP()
        try await client.verifyTOTPSetup(code: "222222", options: .init(friendlyDeviceName: "Phone"))
        let preference = try await client.fetchMFAPreference()
        try await client.updateMFAPreference(sms: .disabled, totp: .preferred, email: .notPreferred)
        let devices = try await client.fetchDevices()
        try await client.rememberDevice()
        try await client.forgetDevice()
        try await client.forgetDevice(device)
        _ = try await homeClient.fetchUserAttributes()

        let done = AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)
        XCTAssertEqual(engine.accountOperationCalls, [
            .fetchUserAttributes(payload: alice.data),
            .updateUserAttributes(payload: alice.data, attributes: [email], clientMetadata: metadata),
            .updateUserAttributes(payload: alice.data, attributes: [email, name], clientMetadata: metadata),
            .sendVerificationCode(payload: alice.data, attributeKey: .email, clientMetadata: metadata),
            .confirmUserAttribute(payload: alice.data, attributeKey: .email, confirmationCode: "111111"),
            .changePassword(payload: alice.data, oldPassword: "old", newPassword: "new"),
            .setUpTOTP(payload: alice.data),
            .verifyTOTPSetup(payload: alice.data, code: "222222", friendlyDeviceName: "Phone"),
            .fetchMFAPreference(payload: alice.data),
            .updateMFAPreference(payload: alice.data, sms: .disabled, totp: .preferred, email: .notPreferred),
            .fetchDevices(payload: alice.data),
            .rememberDevice(payload: alice.data),
            .forgetDevice(payload: alice.data, deviceId: nil),
            .forgetDevice(payload: alice.data, deviceId: "device-2")
        ])
        XCTAssertEqual(other.accountOperationCalls, [.fetchUserAttributes(payload: bob.data)])
        XCTAssertEqual(attributes, [AuthClientUserAttribute(.email, value: "alice@example.com")])
        XCTAssertEqual(single, done)
        XCTAssertEqual(several, [.email: done, .name: done])
        XCTAssertEqual(delivery, FakeSessionEngine.delivery)
        XCTAssertEqual(totp, AuthClientTOTPSetupDetails(sharedSecret: "SECRET", username: "alice"))
        XCTAssertEqual(preference, AuthClientUserMFAPreference(enabled: nil, preferred: nil))
        XCTAssertEqual(devices, [AuthClientDevice(id: "device-1", name: "iPhone")])
        XCTAssertEqual(harness.keychain.writtenAccounts, [])
    }

    /// - Given: a signed-in session whose tokens need a refresh
    /// - When: two signed-in calls run concurrently
    /// - Then:
    ///    - the session refreshes once, and both calls get the refreshed payload
    func testSignedInOperationsRefreshAStalePayloadOnce() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        async let devices = client.fetchDevices()
        async let attributes = client.fetchUserAttributes()
        await latch.waitForArrivals(1)
        // Both calls must be waiting on the one flight before it finishes, or the second could simply find
        // the refreshed payload and prove nothing about joining.
        await waitUntil("both calls wait on the one refresh") { await client.core.refreshFlight.waiterCount == 2 }
        await latch.open()
        _ = try await (devices, attributes)

        XCTAssertEqual(engine.refreshCalls, [stale.data])
        XCTAssertEqual(engine.accountOperationCalls.map(\.payload), [stale.refreshed.data, stale.refreshed.data])
    }

    /// A pending sign-in is not a signed-in user, and a signed-in operation must not disturb it.
    ///
    /// - Given: a signed-out session waiting on a TOTP challenge
    /// - When: `fetchDevices()` is called, then the challenge is answered
    /// - Then:
    ///    - `fetchDevices()` throws `notSignedIn` without calling the engine; the challenge is still pending,
    ///      and `confirmSignIn` completes the sign-in
    func testSignedInOperationsRefuseAPendingSignInAndLeaveIt() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await client.signIn(username: "alice", password: "password")

        await assertThrowsAsync({ try await client.fetchDevices() }) { error in
            guard case .notSignedIn = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(engine.accountOperationCalls, [])
        let pending = await client.currentSessionState()
        XCTAssertEqual(pending, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let result = try await client.confirmSignIn(challengeResponse: "123456")
        XCTAssertEqual(result.nextStep, .done)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// - Given: a federated session
    /// - When: a signed-in operation is called
    /// - Then:
    ///    - it throws `notSignedIn` without refreshing or calling the engine
    func testSignedInOperationsRefuseAFederatedSession() async throws {
        try harness.signIn(work, .federated(stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        await assertThrowsAsync({ try await client.fetchMFAPreference() }) { error in
            guard case .notSignedIn = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(engine.accountOperationCalls, [])
    }

    /// - Given: a signed-out session, and a guest session
    /// - When: a signed-in call is made on each
    /// - Then:
    ///    - each throws `notSignedIn`, and neither engine receives the call
    func testSignedInOperationsRefuseASignedOutOrGuestSession() async throws {
        try harness.signIn(home, .guest(identityId: "us-east-1:guest"))
        let signedOut = try harness.client(work)
        let guest = try harness.client(home)

        for client in [signedOut, guest] {
            await assertThrowsAsync({ try await client.setUpTOTP() }) { error in
                guard case .notSignedIn = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        XCTAssertEqual(harness.engine(for: work)?.accountOperationCalls, [])
        XCTAssertEqual(harness.engine(for: home)?.accountOperationCalls, [])
    }

    /// - Given: a signed-in session whose engine fails a call
    /// - When: the call is made
    /// - Then:
    ///    - an `AuthClientError` passes through, a `SessionEngineError.service` is unwrapped, and anything
    ///      else is `unknown` naming the operation
    func testSignedInOperationFailuresAreMapped() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        engine.scriptAccountOperation(.rememberDevice) { _ in
            throw SessionEngineError.service(.service(.deviceNotTracked, "not tracked", "track it"))
        }
        await assertThrowsAsync({ try await client.rememberDevice() }) { error in
            guard case .service(.deviceNotTracked?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        engine.scriptAccountOperation(.fetchDevices) { _ in throw FixtureError(description: "boom") }
        await assertThrowsAsync({ try await client.fetchDevices() }) { error in
            guard case .unknown(let description, _, let underlying) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "The client could not fetch the devices.")
            XCTAssertTrue(underlying is FixtureError)
        }

        // Only the refresh path may report a dead refresh token (and mark the session expired).
        engine.scriptAccountOperation(.setUpTOTP) { _ in throw SessionEngineError.refreshTokenInvalid }
        await assertThrowsAsync({ try await client.setUpTOTP() }) { error in
            guard case .unknown = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        let expired = await client.core.isExpired
        XCTAssertFalse(expired)
    }

    /// The plugin's single-attribute update reads its key's result from the batch, and fails if it is
    /// missing.
    ///
    /// - Given: an engine whose update result lacks the attribute's key
    /// - When: one attribute is updated
    /// - Then:
    ///    - it throws the plugin's `unknown`
    func testSingleAttributeUpdateNeedsItsKeysResult() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptAccountOperation(.updateUserAttributes) { _ in [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult]() }

        await assertThrowsAsync({ try await client.update(userAttribute: .init(.email, value: "a@example.com")) }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Attribute to be updated does not exist in the result")
        }
    }

    // MARK: Federation

    /// - Given: a signed-out session with an identity pool
    /// - When: it federates, with a developer-provided identity ID
    /// - Then:
    ///    - the engine receives the token, the provider and the options with no current payload, once; the
    ///      engine's federated payload is committed
    func testFederationRoutesToTheEngineAndCommits() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = try await client.federateToIdentityPool(
            withProviderToken: "token",
            for: .oidc("issuer"),
            options: .init(developerProvidedIdentityId: "us-east-1:dev")
        )

        XCTAssertEqual(result.identityId, "us-east-1:federated")
        XCTAssertEqual(engine.accountOperationCalls, [
            .federateToIdentityPool(
                EngineFederationRequest(token: "token", provider: .oidc("issuer"), developerProvidedIdentityId: "us-east-1:dev"),
                current: nil
            )
        ])
        XCTAssertEqual(try harness.storedRecord(work)?.kind, .federated)
    }

    /// The plugin refuses federation on a session signed in to the user pool, before any network call
    /// (`AWSAuthFederateToIdentityPoolTask.swift:87-94`), and clearing on one that is not federated.
    ///
    /// - Given: a session signed in to the user pool, and a signed-out one
    /// - When: the first federates, and both clear a federation
    /// - Then:
    ///    - each throws the plugin's `invalidState`, and no engine is called
    func testFederationRefusesTheStatesThePluginRefuses() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let signedIn = try harness.client(work)
        let signedOut = try harness.client(home)

        await assertThrowsAsync({ try await signedIn.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            guard case .invalidState(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Federation could not be completed.")
        }
        for client in [signedIn, signedOut] {
            await assertThrowsAsync({ try await client.clearFederationToIdentityPool() }) { error in
                guard case .invalidState(let description, _, _) = authError(error) else {
                    return XCTFail("\(error)")
                }
                XCTAssertEqual(description, "Clearing of federation failed.")
            }
        }
        XCTAssertEqual(harness.engine(for: work)?.accountOperationCalls, [])
        XCTAssertEqual(harness.engine(for: home)?.accountOperationCalls, [])
    }

    /// - Given: a federated session
    /// - When: it reports its state, federates again, and clears the federation
    /// - Then:
    ///    - its state is `.federated(identityId:)`; federating reaches the engine with the session's payload;
    ///      clearing leaves it signed out
    func testAFederatedSessionReportsItsIdentityAndMayFederateOrClear() async throws {
        let federated = FakePayload.federated(identityId: "us-east-1:fed")
        try harness.signIn(work, federated)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:fed"))
        _ = try await client.federateToIdentityPool(withProviderToken: "token", for: .google)
        try await client.clearFederationToIdentityPool()
        XCTAssertEqual(engine.accountOperationCalls, [
            .federateToIdentityPool(
                EngineFederationRequest(token: "token", provider: .google, developerProvidedIdentityId: nil),
                current: federated.data
            )
        ])
        let cleared = await client.currentSessionState()
        XCTAssertEqual(cleared, .signedOut)
    }


    /// What `.federated(identityId:)` means for the operations that were written before it.
    ///
    /// - Given: a federated session, and a federated record with no identity ID
    /// - When: the first is fetched, asked for its user, and signed in to; the second reports its state
    /// - Then:
    ///    - the session holds the identity and AWS credentials and no user; `getCurrentUser` throws
    ///      `notSignedIn`; `signIn` throws `invalidState` without calling the engine; the second is `.failed`
    func testTheFederatedStateAcrossTheExistingOperations() async throws {
        let federated = FakePayload.federated(identityId: "us-east-1:fed")
        try harness.signIn(work, federated)
        try harness.signIn(home, .federated(identityId: nil))
        let client = try harness.client(work)
        let broken = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let session = try await client.fetchAuthSession()
        XCTAssertEqual(try session.identityIdResult.get(), "us-east-1:fed")
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, federated.awsCredentials.accessKeyId)
        XCTAssertThrowsError(try session.userSubResult.get())
        await assertThrowsAsync({ try await client.getCurrentUser() }) { error in
            guard case .notSignedIn = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        await assertThrowsAsync({ try await client.signIn(username: "alice", password: "password") }) { error in
            guard case .invalidState = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(engine.signInCalls.count, 0)
        guard case .failed = await broken.currentSessionState() else {
            return XCTFail("a federated record without an identity must not be reported as federated")
        }
    }

    /// - Given: a configuration with no identity pool
    /// - When: the session federates
    /// - Then:
    ///    - it throws `configuration`, and the engine receives nothing
    func testFederationNeedsAnIdentityPool() async throws {
        let client = try harness.client(work, configuration: ClientFixtures.userPoolOnlyConfiguration)
        let engine = try XCTUnwrap(harness.engine(for: work))

        await assertThrowsAsync({ try await client.federateToIdentityPool(withProviderToken: "token", for: .google) }) { error in
            guard case .configuration = authError(error) else {
                return XCTFail("\(error)")
            }
        }
        XCTAssertEqual(engine.accountOperationCalls, [])
    }
}
