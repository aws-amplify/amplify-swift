//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// The base class of the device suites. After the base class has signed the sessions out and deleted the
/// fresh users, it removes each user's device and advanced-security records from this device's keychain
/// (the default access group, the user's pool), which the client keeps per user and never removes itself.
class DeviceTestCase: ClientIntegrationTestCase {

    private var deviceUsers: [FreshUser] = []

    override func makeFreshUser(on pool: SandboxPool, _ options: SandboxSignUp.Options = .init()) async throws -> FreshUser {
        let user = try await super.makeFreshUser(on: pool, options)
        deviceUsers.append(user)
        return user
    }

    override func tearDown() async throws {
        let users = deviceUsers
        deviceUsers = []
        var firstError: Error?
        do {
            try await super.tearDown()
        } catch {
            firstError = error
        }
        for user in users {
            do {
                let pools = try IntegrationTestEnvironment.configuration(user.pool).poolNamespace
                let store = DeviceRecordStore(namespace: SessionStorageNamespace(pools: pools, accessGroup: nil))
                try store.removeDeviceMetadata(for: user.username)
                try store.removeASFDeviceId(for: user.username)
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }
}

/// Helpers for the device suites. Device keys are identifiers: every comparison
/// here is a `Bool` with a fixed message, so no failure prints one.
extension ClientIntegrationTestCase {

    /// Signs `user` in on `client` with `flow` (the client's default, SRP, when `nil`) and checks it
    /// completed.
    func signInToDone(
        _ client: AmplifyCognitoClient,
        _ user: FreshUser,
        flow: AuthClientAuthFlowType? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let result = try await client.signIn(
            username: user.username,
            password: user.password,
            options: AuthClientSignInOptions(authFlowType: flow)
        )
        XCTAssertEqual(result.nextStep, .done, "the sign-in did not complete", file: file, line: line)
    }

    /// The device key Cognito put in the session's current access token (`device_key`): the id
    /// `fetchDevices()` lists this session's device under.
    func thisDeviceKey(_ client: AmplifyCognitoClient) async throws -> String {
        let tokens = try await client.fetchAuthSession().userPoolTokensResult.get()
        return try Self.deviceKey(in: tokens.accessToken)
    }

    /// The `device_key` claim of an access token.
    static func deviceKey(in accessToken: String) throws -> String {
        let claims = try IntegrationTestEnvironment.jwtClaims(accessToken)
        return try XCTUnwrap(claims["device_key"] as? String, "the access token has no device_key claim")
    }

    /// Forces a refresh and returns the new tokens, failing the test if the refresh failed.
    @discardableResult
    func forceRefresh(
        _ client: AmplifyCognitoClient,
        _ description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> AuthClientUserPoolTokens {
        let before = try await client.fetchAuthSession().userPoolTokensResult.get()
        let session = try await client.fetchAuthSession(options: .init(forceRefresh: true))
        let tokens: AuthClientUserPoolTokens
        switch session.userPoolTokensResult {
        case .success(let refreshed):
            tokens = refreshed
        case .failure(let error):
            XCTFail("\(description): the refresh failed (\(error.kind))", file: file, line: line)
            throw error
        }
        XCTAssertFalse(tokens.idToken.isEmpty, "\(description): no id token", file: file, line: line)
        XCTAssertFalse(tokens.accessToken.isEmpty, "\(description): no access token", file: file, line: line)
        XCTAssertTrue(tokens.accessToken != before.accessToken, "\(description): the access token did not change", file: file, line: line)
        let state = await client.currentSessionState()
        guard case .signedIn = state else {
            XCTFail("\(description): the session is no longer signed in", file: file, line: line)
            return tokens
        }
        return tokens
    }

    /// Calls `forgetDevice()` and checks that this session's device, by its `device_key` claim, was the only
    /// device listed before and that none is listed after, as the plugin's forget tests assert
    /// (`devices.count == 0`). Valid because every test signs up its own user, as DV-3 does.
    func assertForgetsThisDevice(
        _ client: AmplifyCognitoClient,
        _ description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let deviceKey = try await thisDeviceKey(client)
        let before = try await client.fetchDevices()
        assertOnlyThisDevice(before, deviceKey, "\(description), before forgetting", file: file, line: line)
        try await client.forgetDevice()
        let after = try await client.fetchDevices()
        XCTAssertEqual(after.count, 0, "\(description): a device is still listed", file: file, line: line)
    }

    /// Checks that `devices` is exactly one device, this session's.
    func assertOnlyThisDevice(
        _ devices: [AuthClientDevice],
        _ deviceKey: String,
        _ description: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(devices.count, 1, "\(description): the device count", file: file, line: line)
        XCTAssertTrue(devices.first?.id == deviceKey, "\(description): the listed device is not this one", file: file, line: line)
    }
}
