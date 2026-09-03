//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import InternalAmplifyCredentials

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AmplifyAWSCredentialsProviderTests: XCTestCase, @unchecked Sendable {

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// An unconfigured Auth category must surface as a thrown error rather than a process abort.
    ///
    /// Reading `Amplify.Auth.plugin` when the category has no plugin trips a `preconditionFailure`. A
    /// credentials provider is reachable from long-lived AWS clients that can outlive
    /// `Amplify.reset()` — the `PinpointContext` cached in `AWSPinpointFactory` is one, because nothing
    /// ever clears that cache — so the provider can genuinely be called in this state and must not take
    /// the whole process down with it.
    ///
    /// - Given: An `AmplifyAWSCredentialsProvider` and an Auth category with no plugin configured
    /// - When:
    ///    - `getCredentials()` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` instead of aborting the process
    ///
    func testGetCredentials_withUnconfiguredAuthCategory_throwsConfigurationError() async {
        XCTAssertFalse(
            Amplify.Auth.isConfiguredWithPlugin,
            "Precondition: Auth must be unconfigured for this test to exercise the guard"
        )

        do {
            _ = try await AmplifyAWSCredentialsProvider().getCredentials()
            XCTFail("Expected getCredentials() to throw when Auth is not configured")
        } catch let error as AuthError {
            guard case .configuration = error else {
                XCTFail("Expected AuthError.configuration, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AuthError.configuration, got \(error)")
        }
    }

    /// Same contract for the `AWSCredentialIdentityResolver` entry point, which the AWS SDK calls.
    ///
    /// - Given: An `AmplifyAWSCredentialsProvider` and an Auth category with no plugin configured
    /// - When:
    ///    - `getIdentity(identityProperties:)` is called
    /// - Then:
    ///    - It throws `AuthError.configuration` instead of aborting the process
    ///
    func testGetIdentity_withUnconfiguredAuthCategory_throwsConfigurationError() async {
        XCTAssertFalse(Amplify.Auth.isConfiguredWithPlugin)

        do {
            _ = try await AmplifyAWSCredentialsProvider().getIdentity()
            XCTFail("Expected getIdentity() to throw when Auth is not configured")
        } catch let error as AuthError {
            guard case .configuration = error else {
                XCTFail("Expected AuthError.configuration, got \(error)")
                return
            }
        } catch {
            XCTFail("Expected AuthError.configuration, got \(error)")
        }
    }
}
