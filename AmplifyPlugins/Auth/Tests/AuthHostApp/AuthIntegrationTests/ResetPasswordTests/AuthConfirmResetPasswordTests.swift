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
    ///    - I should get a userNotFound error. (Gen1 - PreventUserExistenceErrors disabled)
    ///    - I should get a codeExpired error. (Gen2 - PreventUserExistenceErrors enabled)
    ///         (https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-managing-errors.html#cognito-user-pool-managing-errors-password-reset)
    func testUserNotFoundResetPassword() async throws {
        do {
            try await Amplify.Auth.confirmResetPassword(for: "user-non-exists", with: "password", confirmationCode: "123", options: nil)
            XCTFail("resetPassword with non existing user should not return result")
        } catch AuthError.service(_, _, let error as AWSCognitoAuthError) where [.userNotFound, .codeExpired, .limitExceeded].contains(error) {
            return
        } catch {
            XCTFail("Expected .userNotFound, .codeExpired, or .limitExceeded error. received: \(error)")
        }
    }
}
