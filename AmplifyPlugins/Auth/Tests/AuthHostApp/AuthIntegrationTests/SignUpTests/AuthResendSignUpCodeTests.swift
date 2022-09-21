//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthResendSignUpCodeTests: AWSAuthBaseTest {

    /// Test if resendSignUpCode returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke resendSignUpCode with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUserNotFoundResendSignUpCode() async throws {
        do {
            _ = try await Amplify.Auth.resendSignUpCode(for: "user-non-exists")
            XCTFail("resendSignUpCode with non existing user should not return result")
        } catch {
            guard let authError = error as? AuthError, let cognitoError = authError.underlyingError as? AWSCognitoAuthError,
                  case .userNotFound = cognitoError else {
                print(error)
                XCTFail("Should return userNotFound")
                return
            }
        }
    }
}
