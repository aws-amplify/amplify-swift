//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentity
import XCTest

/// Proves the harness can reach the backend from inside the simulator, before the client can sign
/// in. Talks to Cognito through the AWS SDK directly; credentials are asserted on, never printed.
final class CognitoBackendSmokeTests: XCTestCase {

    /// The default backend's identity pool vends guest credentials to this harness.
    ///
    /// - Given: The identity pool from the default backend's outputs, which allows
    ///   unauthenticated identities
    /// - When:
    ///    - `GetId` is called with no logins, then `GetCredentialsForIdentity` for that identity
    /// - Then:
    ///    - An identity id in the pool's region comes back
    ///    - Credentials for that same identity come back, complete and unexpired
    ///
    func testIdentityPoolVendsGuestCredentials() async throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let configuration = try AuthClientConfiguration(
            from: IntegrationTestEnvironment.outputsResource,
            bundle: IntegrationTestEnvironment.outputsBundle(.standard)
        )
        let identityPool = try XCTUnwrap(configuration.identityPool)
        let client = try await CognitoIdentityClient(
            config: CognitoIdentityClient.CognitoIdentityClientConfiguration(region: identityPool.region)
        )

        let getId = try await client.getId(input: GetIdInput(identityPoolId: identityPool.poolId))
        let identityId = try XCTUnwrap(getId.identityId)
        XCTAssertTrue(identityId.hasPrefix("\(identityPool.region):"), "Unexpected identity id shape")

        let output = try await client.getCredentialsForIdentity(
            input: GetCredentialsForIdentityInput(identityId: identityId)
        )
        XCTAssertEqual(output.identityId, identityId)
        let credentials = try XCTUnwrap(output.credentials)
        XCTAssertFalse(credentials.accessKeyId?.isEmpty ?? true, "No access key id")
        XCTAssertFalse(credentials.secretKey?.isEmpty ?? true, "No secret key")
        XCTAssertFalse(credentials.sessionToken?.isEmpty ?? true, "No session token")
        let expiration = try XCTUnwrap(credentials.expiration)
        XCTAssertGreaterThan(expiration, Date())
    }

    /// Every fixture the client suites cannot make themselves reaches the test bundle: nothing is seeded,
    /// so these are the backend's only prerequisites beyond its settings.
    ///
    /// - Given: The plugin's test configuration, copied into the test bundle
    /// - When:
    ///    - Every role's outputs file and the default backend's credentials file are decoded
    /// - Then:
    ///    - Each role's outputs file (or, where only that is there, the Gen2 translation of the plugin's Gen1
    ///      file) loads, and each role the harness reads codes from (`SandboxPool.capturesCodes`: passwordless
    ///      and the two email-MFA backends, the plugin backends that capture them) names a code API (`data`,
    ///      with a URL and an API key). The other roles' files need none: a test that reads a code there
    ///      requires it itself, and fails naming the file
    ///    - The credentials file is in the bundle and holds the keys the client suites use, each non-empty: the
    ///      custom-challenge answer (`custom_challenge_answer`), at least one new-password user
    ///      (`new_password_required_usernames`) and their temporary password
    ///      (`new_password_required_temporary_password`). Other keys, such as the plugin suites', are allowed
    ///
    func testProvisionedUsersAreAvailable() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        for pool in SandboxPool.allCases {
            XCTAssertNoThrow(try IntegrationTestEnvironment.configuration(pool), pool.fixtureName)
        }
        for pool in SandboxPool.allCases where pool.capturesCodes {
            XCTAssertNoThrow(try IntegrationTestEnvironment.codeSinkAPI(pool), "\(pool.outputsResource).json has no code API")
        }

        let credentials = try IntegrationTestEnvironment.credentials()
        XCTAssertTrue(credentials.isPresent, "\(IntegrationTestEnvironment.credentialsResource).json is not in the test bundle")
        XCTAssertFalse(credentials.customChallengeAnswer?.value.isEmpty ?? true, "No custom-challenge answer")
        XCTAssertFalse(credentials.newPasswordRequiredUsernames.isEmpty, "No new-password users")
        XCTAssertFalse(credentials.newPasswordRequiredTemporaryPassword?.value.isEmpty ?? true, "No temporary password")
    }
}
