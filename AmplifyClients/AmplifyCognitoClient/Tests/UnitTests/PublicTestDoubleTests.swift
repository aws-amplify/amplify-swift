//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@_spi(AmplifyExperimental) import AmplifyCognitoClient

/// An app can build the operations' result types for its own test doubles.
///
/// Deliberately a plain `@_spi` import, **not** `@testable`: imports are per file, so this file only
/// compiles while the initializers below are public.
final class PublicTestDoubleTests: XCTestCase {

    /// - Given: an app outside the module
    /// - When: it builds each result type with its public initializer
    /// - Then:
    ///    - every value holds what it was given
    func testResultTypesHavePublicInitializers() throws {
        let tokens = AuthClientUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh")
        let credentials = AuthClientAWSCredentials(
            accessKeyId: "AKID",
            secretAccessKey: "secret",
            sessionToken: "token",
            expiration: Date(timeIntervalSince1970: 0)
        )
        let session = AuthClientSession(
            identityIdResult: .success("identity"),
            awsCredentialsResult: .success(credentials),
            userSubResult: .success("sub"),
            userPoolTokensResult: .success(tokens)
        )
        let result = AuthClientSignInResult(nextStep: .confirmSignInWithTOTPCode)
        let partial = AuthClientSignOutResult.partial(
            revokeTokenError: nil,
            globalSignOutError: AuthClientGlobalSignOutError(error: .unknown("global", "retry")),
            hostedUIError: nil,
            storageError: nil
        )

        XCTAssertEqual(try session.userPoolTokensResult.get(), tokens)
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, "AKID")
        XCTAssertEqual(result.nextStep, .confirmSignInWithTOTPCode)
        XCTAssertTrue(partial.signedOutLocally)
        guard case .partial(let revokeTokenError, let globalSignOutError, _, _) = partial else {
            return XCTFail("expected .partial, got \(partial)")
        }
        XCTAssertNil(revokeTokenError)
        XCTAssertEqual(globalSignOutError?.error.errorDescription, "global")
        XCTAssertEqual(AuthClientRevokeTokenError(error: .unknown("revoke", "retry")).error.errorDescription, "revoke")
        XCTAssertEqual(AuthClientHostedUIError(error: .unknown("page", "retry")).error.errorDescription, "page")
    }

    /// - Given: an app outside the module
    /// - When: it builds each empty options type with its public initializer
    /// - Then:
    ///    - each compiles (the initializers are public), and two values of a type are equal
    func testTheEmptyOptionsAreBuildableOutsideTheModule() {
        XCTAssertEqual(AuthClientChangePasswordOptions(), .init())
        XCTAssertEqual(AuthClientFetchUserAttributesOptions(), .init())
        XCTAssertEqual(AuthClientConfirmUserAttributeOptions(), .init())
        XCTAssertEqual(AuthClientFetchDevicesOptions(), .init())
        XCTAssertEqual(AuthClientRememberDeviceOptions(), .init())
        XCTAssertEqual(AuthClientForgetDeviceOptions(), .init())
        XCTAssertEqual(AuthClientDeleteWebAuthnCredentialOptions(), .init())
        XCTAssertEqual(AuthClientClearFederationToIdentityPoolOptions(), .init())
        #if os(iOS) || os(macOS) || os(visionOS)
        XCTAssertEqual(AuthClientAssociateWebAuthnCredentialOptions(), .init())
        #endif
    }
}
