//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthResetPasswordTests: AWSAuthBaseTest {

    /// Test if resetPassword returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke resetPassword with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUserNotFoundResetPassword() async throws {
        do {
            _ = try await Amplify.Auth.resetPassword(for: "user-non-exists", options: nil)
            XCTFail("resetPassword with non existing user should not return result")
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
