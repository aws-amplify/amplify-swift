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
        let tokens = AmplifyCognitoClientUserPoolTokens(idToken: "id", accessToken: "access", refreshToken: "refresh")
        let credentials = AmplifyCognitoClientAWSCredentials(
            accessKeyId: "AKID",
            secretAccessKey: "secret",
            sessionToken: "token",
            expiration: Date(timeIntervalSince1970: 0)
        )
        let session = AmplifyCognitoClientSession(
            identityId: "identity",
            awsCredentials: credentials,
            userSub: "sub",
            userPoolTokens: tokens
        )
        let result = AmplifyCognitoClientSignInResult(nextStep: .confirmSignInWithTOTPCode)
        let partial = AmplifyCognitoClientSignOutResult.partial(
            revokeTokenError: nil,
            globalSignOutError: AmplifyCognitoClientGlobalSignOutError(error: .unknown("global", "retry")),
            hostedUIError: nil,
            storageError: nil
        )

        XCTAssertEqual(session.userPoolTokens, tokens)
        XCTAssertEqual(session.awsCredentials?.accessKeyId, "AKID")
        XCTAssertEqual(result.nextStep, .confirmSignInWithTOTPCode)
        XCTAssertTrue(partial.signedOutLocally)
        guard case .partial(let revokeTokenError, let globalSignOutError, _, _) = partial else {
            return XCTFail("expected .partial, got \(partial)")
        }
        XCTAssertNil(revokeTokenError)
        XCTAssertEqual(globalSignOutError?.error.errorDescription, "global")
        XCTAssertEqual(AmplifyCognitoClientRevokeTokenError(error: .unknown("revoke", "retry")).error.errorDescription, "revoke")
        XCTAssertEqual(AmplifyCognitoClientHostedUIError(error: .unknown("page", "retry")).error.errorDescription, "page")
    }

    /// - Given: an app outside the module
    /// - When: it builds each empty options type with its public initializer
    /// - Then:
    ///    - each compiles (the initializers are public), and two values of a type are equal
    func testTheEmptyOptionsAreBuildableOutsideTheModule() {
        XCTAssertEqual(AmplifyCognitoClientChangePasswordOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientFetchUserAttributesOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientConfirmUserAttributeOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientFetchDevicesOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientRememberDeviceOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientForgetDeviceOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientDeleteWebAuthnCredentialOptions(), .init())
        XCTAssertEqual(AmplifyCognitoClientClearFederationToIdentityPoolOptions(), .init())
        #if os(iOS) || os(macOS) || os(visionOS)
        XCTAssertEqual(AmplifyCognitoClientAssociateWebAuthnCredentialOptions(), .init())
        #endif
    }
}
