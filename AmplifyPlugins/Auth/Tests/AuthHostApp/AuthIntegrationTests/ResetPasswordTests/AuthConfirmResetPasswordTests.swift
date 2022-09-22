//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthConfirmResetPasswordTests: AWSAuthBaseTest {

    /// Test if confirmResetPassword returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke confirmResetPassword with the user
    /// - Then:
    ///    - I should get a userNotFound error.
    ///
    func testUserNotFoundResetPassword() async throws {
        do {
            try await Amplify.Auth.confirmResetPassword(for: "user-non-exists", with: "password", confirmationCode: "123", options: nil)
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
