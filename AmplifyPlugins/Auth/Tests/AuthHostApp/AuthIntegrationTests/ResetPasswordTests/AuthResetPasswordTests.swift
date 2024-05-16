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
            let randomUserNotExists = UUID().uuidString
            let result = try await Amplify.Auth.resetPassword(for: randomUserNotExists, options: nil)

            // App clients with "Prevent user existence errors" enabled will return a simulated result
            // https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-managing-errors.html#cognito-user-pool-managing-errors-password-reset
            // Gen2 configuration is enabled with Prevent User existence errors, while Gen1 backend is not.
            if useGen2Configuration {
                XCTAssertFalse(result.isPasswordReset)
                guard case .confirmResetPasswordWithCode = result.nextStep else {
                    XCTFail("Expected confirmResultPasswordCode in result, result: \(result)")
                    return
                }
            } else {
                XCTFail("resetPassword with non existing user should not return result, result returned: \(result)")
            }
        } catch AuthError.service(_, _, let error as AWSCognitoAuthError) where [.userNotFound, .limitExceeded].contains(error) {
            return
        } catch {
            XCTFail("Expected .userNotFound or .limitExceeded error. received: \(error)")
        }
    }
}
