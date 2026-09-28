//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentity
import XCTest

/// Proves the harness can reach the sandbox from inside the simulator, before the client can sign
/// in. Talks to Cognito through the AWS SDK directly; credentials are asserted on, never printed.
final class CognitoBackendSmokeTests: XCTestCase {

    /// The sandbox identity pool vends guest credentials to this harness.
    ///
    /// - Given: The identity pool from the provisioned `amplify_outputs.json`, which allows
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
            bundle: IntegrationTestEnvironment.bundle
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

    /// Every provisioned user, and carol's TOTP secret, reach the test bundle.
    ///
    /// - Given: The sandbox's `users.json`, copied into the test bundle
    /// - When:
    ///    - It is decoded
    /// - Then:
    ///    - It holds every key the client suites use: passwords for `alice`, `bob`, `carol` and `erin`,
    ///      `dave`'s temporary and new passwords, `carol`'s TOTP secret, and the parity secrets (the code
    ///      sink's API key and the custom-challenge answer), each non-empty. Other keys — such as the ones
    ///      the plugin suites' provisioning adds — are allowed
    ///    - `dave`'s two passwords differ, so the new-password challenge really changes his password
    ///
    func testProvisionedUsersAreAvailable() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let url = try XCTUnwrap(IntegrationTestEnvironment.bundle.url(
            forResource: IntegrationTestEnvironment.usersResource,
            withExtension: "json"
        ))
        let fields = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: String])
        let missing = Set(SandboxUsers.requiredKeys).subtracting(fields.keys)
        XCTAssertTrue(missing.isEmpty, "users.json is missing \(missing.sorted())")

        let users = try IntegrationTestEnvironment.users()
        let passwords = [users.alice, users.bob, users.carol, users.dave, users.daveNewPassword, users.erin]
        XCTAssertEqual(passwords.map(\.username), ["alice", "bob", "carol", "dave", "dave", "erin"])
        for user in passwords {
            XCTAssertFalse(user.password.isEmpty, "\(user) has an empty password")
        }
        XCTAssertFalse(users.carolTOTPSecret.base32.isEmpty, "carol has no TOTP secret")
        XCTAssertFalse(users.codeSinkAPIKey.value.isEmpty, "No code sink API key")
        XCTAssertFalse(users.customChallengeAnswer.value.isEmpty, "No custom-challenge answer")
        // Not XCTAssertNotEqual: its failure message would print both passwords.
        XCTAssertFalse(users.dave.password == users.daveNewPassword.password, "dave's temporary and new passwords are the same")
    }
}
