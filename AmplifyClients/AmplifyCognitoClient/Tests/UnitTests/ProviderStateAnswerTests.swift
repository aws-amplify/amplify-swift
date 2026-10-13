//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// What the providers and the operations on the signed-in user answer while a sign-in waits on a challenge over a
/// session that holds credentials, and for a federated session whose credentials need a refresh.
final class ProviderStateAnswerTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let smsCode = AuthClientSignInStep.confirmSignInWithSMSMFACode(
        AuthClientCodeDeliveryDetails(destination: .sms("+1***"), attributeKey: .phoneNumber),
        nil
    )

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    private func credentialsError(_ body: () async throws -> some Any, file: StaticString = #filePath, line: UInt = #line) async -> CredentialsError? {
        do {
            _ = try await body()
            XCTFail("expected an error", file: file, line: line)
            return nil
        } catch let error as CredentialsError {
            return error
        } catch {
            XCTFail("expected a CredentialsError, got \(error)", file: file, line: line)
            return nil
        }
    }

    /// Starts a sign-in on `client` that stops on the SMS code challenge.
    private func startChallengedSignIn(_ client: AmplifyCognitoClient, engine: FakeSessionEngine) async throws {
        engine.scriptSignIn { [smsCode] _, _ in .challenge(smsCode) }
        let result = try await client.signInForTest("alice")
        XCTAssertEqual(result.nextStep, smsCode)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .awaitingChallenge(smsCode))
    }

    // MARK: A pending challenge

    /// The plugin keeps vending a guest's credentials while a sign-in is pending, and `fetchAuthSession()` does too.
    /// `notSignedIn` (`.discard`) would have a consumer drop the guest's buffered work.
    ///
    /// - Given: a guest session whose sign-in waits on an SMS code
    /// - When: both providers are asked
    /// - Then:
    ///    - the AWS credentials are the guest's, as `fetchAuthSession()` reports them; the access token throws
    ///      `notSignedIn`, as for any guest
    func testAGuestWaitingOnAChallengeKeepsVendingItsCredentials() async throws {
        let guest = FakePayload.guest(identityId: "us-east-1:guest")
        try harness.signIn(work, guest)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        try await startChallengedSignIn(client, engine: engine)

        let credentials = try await client.credentialsProvider.resolve()
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }
        let session = try await client.fetchAuthSession()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, guest.awsCredentials)
        XCTAssertEqual(try session.awsCredentialsResult.get(), AuthClientAWSCredentials(guest.awsCredentials))
        XCTAssertEqual(token?.isNotSignedIn, true, "\(String(describing: token))")
    }

    /// An expired user re-authenticating keeps `sessionExpired` (`.retryAfterReauthentication`) for the length of
    /// the challenge, so a consumer keeps what it held for the re-authentication.
    ///
    /// - Given: a signed-in session whose refresh token is dead, and its user's sign-in waiting on an SMS code
    /// - When: both providers are asked
    /// - Then:
    ///    - both throw `sessionExpired`, disposition `.retryAfterReauthentication`, not `notSignedIn`
    func testAnExpiredSessionWaitingOnAChallengeStaysExpired() async throws {
        try harness.signIn(work, .signedIn("alice", stale: true))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let expired = await credentialsError { try await client.credentialsProvider.resolve() }
        XCTAssertEqual(expired?.isSessionExpired, true, "\(String(describing: expired))")
        try await startChallengedSignIn(client, engine: engine)

        let aws = await credentialsError { try await client.credentialsProvider.resolve() }
        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }

        XCTAssertEqual(aws?.isSessionExpired, true, "\(String(describing: aws))")
        XCTAssertEqual(aws?.disposition, .retryAfterReauthentication)
        XCTAssertEqual(token?.isSessionExpired, true, "\(String(describing: token))")
        XCTAssertEqual(token?.disposition, .retryAfterReauthentication)
    }

    /// The operations on the signed-in user still refuse a pending sign-in: it is not a signed-in user.
    ///
    /// - Given: a guest session, and an expired session, each with a sign-in waiting on an SMS code
    /// - When: each fetches its user's attributes and deletes its user
    /// - Then:
    ///    - every call throws `notSignedIn`; nothing is refreshed or deleted
    func testOperationsOnTheUserRefuseAPendingChallenge() async throws {
        let home = ClientFixtures.id("home")
        try harness.signIn(work, .guest())
        try harness.signIn(home, .signedIn("alice", stale: true))
        let guestClient = try harness.client(work)
        let expiredClient = try harness.client(home)
        let guestEngine = try XCTUnwrap(harness.engine(for: work))
        let expiredEngine = try XCTUnwrap(harness.engine(for: home))
        expiredEngine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        _ = await credentialsError { try await expiredClient.credentialsProvider.resolve() }
        try await startChallengedSignIn(guestClient, engine: guestEngine)
        try await startChallengedSignIn(expiredClient, engine: expiredEngine)

        for client in [guestClient, expiredClient] {
            let attributes = await authClientError { try await client.fetchUserAttributes() }
            let deletion = await authClientError { try await client.deleteUser() }

            XCTAssertEqual(attributes?.kind, .notSignedIn, "\(String(describing: attributes))")
            XCTAssertEqual(deletion?.kind, .notSignedIn, "\(String(describing: deletion))")
        }
        XCTAssertEqual(guestEngine.refreshCalls.count, 0)
        XCTAssertEqual(expiredEngine.refreshCalls.count, 1)
        XCTAssertEqual(guestEngine.deleteUserCalls, [])
        XCTAssertEqual(expiredEngine.deleteUserCalls, [])
    }

    // MARK: A federated session

    /// A federated session has no user pool user, so its refresh is never run for a call that needs one: a refused
    /// provider token would otherwise mark the session expired and answer `sessionExpired`.
    ///
    /// - Given: a federated session whose AWS credentials need a refresh, and a provider token the identity pool
    ///   now refuses
    /// - When: the token provider is asked, and the user is deleted
    /// - Then:
    ///    - the token provider throws `notConfigured`, `deleteUser()` throws `notSignedIn`
    ///    - neither refreshes, no `.sessionExpired` is sent, and the session stays federated
    func testAStaleFederatedSessionRefusesTokenCallsWithoutRefreshing() async throws {
        let federated = FakePayload.federated(identityId: "us-east-1:fed", stale: true)
        try harness.signIn(work, federated)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptRefresh { _ in throw SessionEngineError.refreshTokenInvalid }
        let events = StreamRecorder(client.listenToAuthEvents())

        let token = await credentialsError { try await client.userPoolTokenProvider.accessToken() }
        let deletion = await authClientError { try await client.deleteUser() }

        XCTAssertEqual(token?.isNotConfigured, true, "\(String(describing: token))")
        XCTAssertEqual(deletion?.kind, .notSignedIn, "\(String(describing: deletion))")
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(engine.deleteUserCalls, [])
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .federated(identityId: "us-east-1:fed"))
    }
}
