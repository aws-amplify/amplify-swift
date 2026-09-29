//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import Foundation
import XCTest

/// The users the base suites need are in the state they need (P-1 … P-4), on the
/// default backend: a user with no MFA preference, a TOTP user, a new-password user, and a user signed up
/// with a password. None is seeded: each test signs its own user up and deletes it, except the new-password
/// user, which only an administrator can make (the credentials file's `new_password_required_usernames`).
///
/// These check the users through a plain SDK client with `USER_PASSWORD_AUTH`, independently of the client
/// under test, so a failure here points at the backend rather than at the client; only the TOTP user is
/// enrolled through the client, as the client suites enroll theirs. Every Cognito response that carries a
/// refresh token has its revocation registered as a teardown block straight away, so it is revoked however
/// the test ends.
final class SandboxProvisioningTests: ClientMFATestCase {

    /// A user with no MFA preference is not challenged, although the pool's MFA is optional (P-1).
    ///
    /// - Given: The default backend, with MFA optional and TOTP enabled, and a fresh user with no MFA
    ///   preference
    /// - When:
    ///    - The user signs in with its password
    /// - Then:
    ///    - Tokens come back with no challenge
    ///    - The access token is the user's, issued to the configured app client
    ///
    func testUserWithoutMFAPreferenceSignsInWithoutAChallenge() async throws {
        let sandbox = try Sandbox()
        let user = try await makeSignInUser()

        let output = try await sandbox.initiatePasswordAuth(user)
        sandbox.revokeAtTeardown(output.authenticationResult, of: self)

        XCTAssertNil(output.challengeName)
        let tokens = try XCTUnwrap(output.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertTrue(claims["username"] as? String == user.username, "the access token names another user")
        XCTAssertEqual(claims["token_use"] as? String, "access")
        XCTAssertTrue(claims["client_id"] as? String == sandbox.appClientId, "the token is not the configured app client's")
    }

    /// A TOTP user is challenged for TOTP, and a code from its secret completes the challenge (P-2).
    ///
    /// - Given: A fresh user who enrolled TOTP through the client (`setUpTOTP`, `verifyTOTPSetup`) and made
    ///   it preferred, then signed out, and the secret it recorded
    /// - When:
    ///    - The user signs in with its password
    ///    - The challenge is answered with a fresh code
    /// - Then:
    ///    - The sign-in returns `SOFTWARE_TOKEN_MFA` with a session
    ///    - The answer returns the user's tokens
    ///
    func testTOTPUserIsChallengedAndAFreshCodeCompletesTheChallenge() async throws {
        let sandbox = try Sandbox()
        let (client, user) = try await signedInFreshUser("totp-provisioning")
        let secret = try await enrollTOTP(client, user)
        try await client.updateMFAPreference(sms: nil, totp: .preferred)
        _ = try await client.signOut()

        let challenge = try await sandbox.initiatePasswordAuth(user.testUser)
        sandbox.revokeAtTeardown(challenge.authenticationResult, of: self)
        XCTAssertEqual(challenge.challengeName, .softwareTokenMfa)
        let session = try XCTUnwrap(challenge.session)

        let code = try await TOTP.freshCode(secret: secret)
        let answer = try await sandbox.userPool.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .softwareTokenMfa,
            challengeResponses: ["USERNAME": user.username, "SOFTWARE_TOKEN_MFA_CODE": code],
            clientId: sandbox.appClientId,
            session: session
        ))
        sandbox.revokeAtTeardown(answer.authenticationResult, of: self)

        let tokens = try XCTUnwrap(answer.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertTrue(claims["username"] as? String == user.username, "the access token names another user")
    }

    /// A new-password user must set a new password (P-3): the credentials file's users are in
    /// `FORCE_CHANGE_PASSWORD` until one is used. Unless the challenge suite already tried to set one in this
    /// run (`ChallengeTests` runs first in the default order): then that user is in one of two states, and
    /// must be in one of them.
    ///
    /// Each user is used once, and another run may take one at any time, so the check reads the users in
    /// order and stops at the first still in that state; a user already used (its temporary password refused,
    /// and Cognito no longer holding it in that state) is passed over. A refused temporary password for a user
    /// still in that state fails the test as a wrong temporary password.
    ///
    /// - Given: The new-password users and their temporary password, from the credentials file
    /// - When:
    ///    - Each signs in with the temporary password, until one is challenged; if this run's challenge test
    ///      tried a new password, that user signs in with the temporary one, and if it is refused, with the
    ///      new one
    /// - Then:
    ///    - With the temporary password: the sign-in returns `NEW_PASSWORD_REQUIRED` with a session, and no
    ///      tokens. The challenge is not answered, so the user stays ready for the challenge suite
    ///    - Otherwise, only after the attempt: the new password signs in, with no challenge, as that user
    ///
    func testForceChangePasswordUserIsAskedForANewPassword() async throws {
        let sandbox = try Sandbox()
        let (candidates, temporary) = try IntegrationTestEnvironment.credentials().requireNewPasswordUsers()

        if let attempted = PerRunUsers.newPasswordAttempt {
            do {
                let output = try await sandbox.initiatePasswordAuth(TestUser(username: attempted.username, password: temporary.value))
                sandbox.revokeAtTeardown(output.authenticationResult, of: self)
                XCTAssertEqual(output.challengeName, .newPasswordRequired, "the attempt left the temporary password")
                return
            } catch is NotAuthorizedException {
                // The attempt changed the password: the new one must work.
            }
            let output = try await sandbox.initiatePasswordAuth(attempted)
            sandbox.revokeAtTeardown(output.authenticationResult, of: self)
            XCTAssertNil(output.challengeName)
            let tokens = try XCTUnwrap(output.authenticationResult)
            let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
            XCTAssertTrue(
                (claims["username"] as? String)?.lowercased() == attempted.username.lowercased(),
                "the access token names another user"
            )
            return
        }
        for username in candidates {
            let output: InitiateAuthOutput
            do {
                output = try await sandbox.initiatePasswordAuth(TestUser(username: username, password: temporary.value))
            } catch is NotAuthorizedException {
                guard try await !PerRunUsers.stillAwaitsANewPassword(username, on: SandboxPools.pool(.standard)) else {
                    return XCTFail(PerRunUsers.wrongTemporaryPassword)
                }
                // Used up, by an earlier run or by one running now.
                continue
            }
            sandbox.revokeAtTeardown(output.authenticationResult, of: self)

            XCTAssertEqual(output.challengeName, .newPasswordRequired)
            XCTAssertNotNil(output.session)
            XCTAssertNil(output.authenticationResult)
            return
        }
        XCTFail("""
        None of the \(candidates.count) new-password users in \(IntegrationTestEnvironment.credentialsResource).json \
        is still in FORCE_CHANGE_PASSWORD: the backend must reset them (or list new ones) before each run.
        """)
    }

    /// A user signed up with a password signs in with it (P-4).
    ///
    /// - Given: A fresh user, signed up on the default backend with a password
    /// - When:
    ///    - The user signs in with that password
    /// - Then:
    ///    - Tokens come back with no challenge, for that user
    ///
    func testRecreatedUserSignsInWithHerStoredPassword() async throws {
        let sandbox = try Sandbox()
        let erin = try await makeSignInUser()

        let output = try await sandbox.initiatePasswordAuth(erin)
        sandbox.revokeAtTeardown(output.authenticationResult, of: self)

        XCTAssertNil(output.challengeName)
        let tokens = try XCTUnwrap(output.authenticationResult)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        XCTAssertTrue(claims["username"] as? String == erin.username, "the access token names another user")
    }
}

/// A plain user pool SDK client for the default backend's user pool and app client.
private struct Sandbox {
    let appClientId: String
    let userPool: CognitoIdentityProviderClient

    init() throws {
        let pool = try XCTUnwrap(IntegrationTestEnvironment.configuration().userPool)
        self.appClientId = pool.appClientId
        self.userPool = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: pool.region)
        )
    }

    func initiatePasswordAuth(_ user: TestUser) async throws -> InitiateAuthOutput {
        try await userPool.initiateAuth(input: InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": user.username, "PASSWORD": user.password],
            clientId: appClientId
        ))
    }

    /// If `result` carries a refresh token, registers its revocation as a teardown block of `testCase`.
    /// Called straight after every Cognito response, before any assertion that could throw, so the user is
    /// left holding no valid refresh token whatever the test does next.
    func revokeAtTeardown(
        _ result: CognitoIdentityProviderClientTypes.AuthenticationResultType?,
        of testCase: XCTestCase
    ) {
        guard let refreshToken = result?.refreshToken else {
            return
        }
        let userPool = userPool
        let clientId = appClientId
        testCase.addTeardownBlock {
            _ = try await userPool.revokeToken(input: RevokeTokenInput(clientId: clientId, token: refreshToken))
        }
    }
}
