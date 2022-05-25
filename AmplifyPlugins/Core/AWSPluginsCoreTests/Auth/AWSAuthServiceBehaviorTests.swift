//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSPluginsCore
import AWSCore

class AWSAuthServiceBehaviorTests: XCTestCase {
    // MARK: Tests for change from blocking to non-blocking
    /**
     Confirm that calling the non-blocking replacements of `getIdentityId()` (`getIdentityID(completion:)`)
     and `getToken()` (`getUserPoolAccessToken(completion:)`) in `AWSAuthServiceBehavior` conforming
     objects that have yet to implement the non-blocking methods, will act as a pass through to
     the existing blocking methods.

     - IMPORTANT: This tests can be removed after the deprecation process of
     the blocking methods `getIdentityId` and `getToken` is complete
     */

    func testNonBlockingDefaultImplementationSuccess() {
        let mockAWSAuthService: AWSAuthServiceBehavior = _MockAWSAuthService.init(
            identityID: .success("42"),
            userPoolAccessToken: .success("25")
        )

        /// Calling `getIdentityID(completion:)` on an `AWSAuthServiceBehavior` conforming type
        /// without an explicit implementation should use the now deprecated `getIdentityId()` method as a
        /// default implementation.
        mockAWSAuthService.getIdentityID {
            switch $0 {
            case .success(let id): XCTAssertEqual(id, "42")
            case .failure: XCTFail("This instance of _MockAWSAuthService should return .success")
            }
        }

        /// Calling `getUserPoolAccessToken(completion:)` on an `AWSAuthServiceBehavior` conforming type
        /// without an explicit implementation should use the now deprecated `getToken()` method as a
        /// default implementation.
        mockAWSAuthService.getUserPoolAccessToken {
            switch $0 {
            case .success(let id): XCTAssertEqual(id, "25")
            case .failure: XCTFail("This instance of _MockAWSAuthService should return .success")
            }
        }
    }

    func testNonBlockingDefaultImplementationFailure() {
        let identityIDErrorDescription = "identityID_description"
        let identityIDErrorRecovery = "identityID_recovery"

        let userPoolAccessTokenIDErrorDescription = "userPoolAccessToken_description"
        let userPoolAccessTokenIDErrorRecovery = "userPoolAccessToken_recovery"

        let mockAWSAuthService: AWSAuthServiceBehavior = _MockAWSAuthService.init(
            identityID: .failure(
                .notAuthorized(
                    identityIDErrorDescription,
                    identityIDErrorRecovery
                )
            ),
            userPoolAccessToken: .failure(
                .invalidState(
                    userPoolAccessTokenIDErrorDescription,
                    userPoolAccessTokenIDErrorRecovery
                )
            )
        )

        /// Calling `getIdentityID(completion:)` on an `AWSAuthServiceBehavior` conforming type
        /// without an explicit implementation should use the now deprecated `getIdentityId()` method as a
        /// default implementation.
        mockAWSAuthService.getIdentityID {
            switch $0 {
            case let .failure(.notAuthorized(description, recovery, _)):
                XCTAssertEqual(description, identityIDErrorDescription)
                XCTAssertEqual(recovery, identityIDErrorRecovery)
            default: XCTFail("This instance of _MockAWSAuthService should return .failure(.notAuthorized)")
            }
        }

        /// Calling `getUserPoolAccessToken(completion:)` on an `AWSAuthServiceBehavior` conforming type
        /// without an explicit implementation should use the now deprecated `getToken()` method as a
        /// default implementation.
        mockAWSAuthService.getUserPoolAccessToken {
            switch $0 {
            case let .failure(.invalidState(description, recovery, _)):
                XCTAssertEqual(description, userPoolAccessTokenIDErrorDescription)
                XCTAssertEqual(recovery, userPoolAccessTokenIDErrorRecovery)
            default: XCTFail("This instance of _MockAWSAuthService should return .failure(.invalidState)")
            }
        }
    }
}

private class _MockAWSAuthService: AWSAuthServiceBehavior {
    let identityID: () -> Result<String, AuthError>
    let userPoolAccessToken: () -> Result<String, AuthError>

    init(
        identityID: @escaping @autoclosure () -> Result<String, AuthError>,
        userPoolAccessToken: @escaping @autoclosure () -> Result<String, AuthError>
    ) {
        self.identityID = identityID
        self.userPoolAccessToken = userPoolAccessToken
    }

    func getCredentialsProvider() -> AWSCredentialsProvider {
        AWSCognitoCredentialsProvider()
    }

    func getIdentityId() -> Result<String, AuthError> {
        identityID()
    }

    func getToken() -> Result<String, AuthError> {
        userPoolAccessToken()
    }

    func getTokenClaims(tokenString: String) -> Result<[String: AnyObject], AuthError> {
        .success([:])
    }
}
