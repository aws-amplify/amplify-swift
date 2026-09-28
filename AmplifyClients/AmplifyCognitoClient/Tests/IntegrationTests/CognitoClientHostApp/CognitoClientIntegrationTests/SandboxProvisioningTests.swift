//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest

/// The sandbox users are in the state the base suites need (P-1 … P-4).
///
/// These talk to Cognito through a plain SDK client with `USER_PASSWORD_AUTH`, independently of the
/// client under test, so a failure here points at provisioning rather than at the client. Every Cognito
/// response that carries a refresh token has its revocation registered as a teardown block straight
/// away, so it is revoked however the test ends.
final class SandboxProvisioningTests: XCTestCase {

    /// A user with no MFA preference is not challenged, although the pool's MFA is optional (P-1).
    ///
    /// - Given: The pool with MFA optional and TOTP enabled, and `alice`, who has no MFA preference
    /// - When:
    ///    - `alice` signs in with her password
    /// - Then:
    ///    - Tokens come back with no challenge
    ///    - The access token is `alice`'s, issued to the provisioned app client
    ///
    func testUserWithoutMFAPreferenceSignsInWithoutAChallenge() async throws {
        let sandbox = try Sandbox()
        let alice = try IntegrationTestEnvironment.users().alice

        let output = try await sandbox.initiatePasswordAuth(alice)
        sandbox.revokeAtTeardown(output.authenticationResult, of: self)

        XCTAssertNil(output.challengeName)
        let tokens = try XCTUnwrap(output.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertEqual(claims["username"] as? String, "alice")
        XCTAssertEqual(claims["token_use"] as? String, "access")
        XCTAssertEqual(claims["client_id"] as? String, sandbox.state.appClientId)
    }

    /// `carol` is challenged for TOTP, and a code from her stored secret completes the challenge (P-2).
    ///
    /// - Given: `carol`, TOTP enrolled and preferred, and her secret from `users.json`
    /// - When:
    ///    - She signs in with her password
    ///    - The challenge is answered with a fresh code
    /// - Then:
    ///    - The sign-in returns `SOFTWARE_TOKEN_MFA` with a session
    ///    - The answer returns `carol`'s tokens
    ///
    func testTOTPUserIsChallengedAndAFreshCodeCompletesTheChallenge() async throws {
        let sandbox = try Sandbox()
        let users = try IntegrationTestEnvironment.users()

        let challenge = try await sandbox.initiatePasswordAuth(users.carol)
        sandbox.revokeAtTeardown(challenge.authenticationResult, of: self)
        XCTAssertEqual(challenge.challengeName, .softwareTokenMfa)
        let session = try XCTUnwrap(challenge.session)

        let code = try await TOTP.freshCode(secret: users.carolTOTPSecret)
        let answer = try await sandbox.userPool.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .softwareTokenMfa,
            challengeResponses: ["USERNAME": users.carol.username, "SOFTWARE_TOKEN_MFA_CODE": code],
            clientId: sandbox.state.appClientId,
            session: session
        ))
        sandbox.revokeAtTeardown(answer.authenticationResult, of: self)

        let tokens = try XCTUnwrap(answer.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertEqual(claims["username"] as? String, "carol")
    }

    /// `dave` must set a new password: `prepare-run.sh` left him in `FORCE_CHANGE_PASSWORD` (P-3).
    /// Unless the challenge suite already tried to set it in this run (`ChallengeTests` runs first in the
    /// default order): then he is in one of two states, and must be in one of them.
    ///
    /// - Given: `dave`, reset by `prepare-run.sh` with his stored temporary password
    /// - When:
    ///    - He signs in with it; if this run's challenge test tried the new password and the temporary one
    ///      is refused, with the new one
    /// - Then:
    ///    - With the temporary password: the sign-in returns `NEW_PASSWORD_REQUIRED` with a session, and
    ///      no tokens. The challenge is not answered, so `dave` stays ready for the challenge suite
    ///    - Otherwise, only after the attempt: the new password signs in, with no challenge, as `dave`
    ///
    func testForceChangePasswordUserIsAskedForANewPassword() async throws {
        let sandbox = try Sandbox()
        let users = try IntegrationTestEnvironment.users()

        if PerRunUsers.daveNewPasswordAttempted {
            do {
                let output = try await sandbox.initiatePasswordAuth(users.dave)
                sandbox.revokeAtTeardown(output.authenticationResult, of: self)
                XCTAssertEqual(output.challengeName, .newPasswordRequired, "the attempt left dave's temporary password")
                return
            } catch is NotAuthorizedException {
                // The attempt changed the password: the new one must work.
            }
            let output = try await sandbox.initiatePasswordAuth(users.daveNewPassword)
            sandbox.revokeAtTeardown(output.authenticationResult, of: self)
            XCTAssertNil(output.challengeName)
            let tokens = try XCTUnwrap(output.authenticationResult)
            let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
            XCTAssertEqual(claims["username"] as? String, "dave")
            return
        }
        let output = try await sandbox.initiatePasswordAuth(users.dave)
        sandbox.revokeAtTeardown(output.authenticationResult, of: self)

        XCTAssertEqual(output.challengeName, .newPasswordRequired)
        XCTAssertNotNil(output.session)
        XCTAssertNil(output.authenticationResult)
    }

    /// `erin` exists with her stored permanent password: `prepare-run.sh` recreated her (P-4).
    ///
    /// - Given: `erin`, recreated by `prepare-run.sh`
    /// - When:
    ///    - She signs in with her password
    /// - Then:
    ///    - Tokens come back with no challenge, for `erin`
    ///
    func testRecreatedUserSignsInWithHerStoredPassword() async throws {
        let sandbox = try Sandbox()
        let erin = try IntegrationTestEnvironment.users().erin

        let output = try await sandbox.initiatePasswordAuth(erin)
        sandbox.revokeAtTeardown(output.authenticationResult, of: self)

        XCTAssertNil(output.challengeName)
        let tokens = try XCTUnwrap(output.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertEqual(claims["username"] as? String, "erin")
    }
}

/// A plain user pool SDK client for the provisioned pool.
private struct Sandbox {
    let state: SandboxState
    let userPool: CognitoIdentityProviderClient

    init() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        self.state = try IntegrationTestEnvironment.state()
        self.userPool = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: state.region)
        )
    }

    func initiatePasswordAuth(_ user: TestUser) async throws -> InitiateAuthOutput {
        try await userPool.initiateAuth(input: InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": user.username, "PASSWORD": user.password],
            clientId: state.appClientId
        ))
    }

    /// If `result` carries a refresh token, registers its revocation as a teardown block of `testCase`.
    /// Called straight after every Cognito response, before any assertion that could throw, so the sandbox
    /// user is left holding no valid refresh token whatever the test does next.
    func revokeAtTeardown(
        _ result: CognitoIdentityProviderClientTypes.AuthenticationResultType?,
        of testCase: XCTestCase
    ) {
        guard let refreshToken = result?.refreshToken else {
            return
        }
        let userPool = userPool
        let clientId = state.appClientId
        testCase.addTeardownBlock {
            _ = try await userPool.revokeToken(input: RevokeTokenInput(clientId: clientId, token: refreshToken))
        }
    }
}
