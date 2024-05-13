//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AuthConfirmSignUpTests: AWSAuthBaseTest {

    /// Test if confirmSignUp returns userNotFound error for a non existing user
    ///
    /// - Given: A user which is not registered to the configured user pool
    /// - When:
    ///    - I invoke confirmSignUp with the user
    /// - Then:
    ///    - I should get a userNotFound error. (Gen1 - PreventUserExistenceErrors disabled)
    ///    - I should get a codeMismatch error. (Gen2 - PreventUserExistenceErrors enabled)
    ///         (https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-managing-errors.html#cognito-user-pool-managing-errors-password-reset)
    ///
    func testUserNotFoundConfirmSignUp() async throws {
        do {
            _ = try await Amplify.Auth.confirmSignUp(for: "user-non-exists", confirmationCode: "232")
            XCTFail("Confirm signUp with non existing user should not return result")
        } catch {
            guard let authError = error as? AuthError, let cognitoError = authError.underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should return cognitoAuthError")
                return
            }

            switch cognitoError {
            case .userNotFound, .codeMismatch:
                return
            default:
                XCTFail("Should be either `userNotFound` or `codeMismatch`")
            }
        }
    }

    /// Test confirmSignUp return validation error
    ///
    /// - Given: An invalid input to confirmSignUp like empty code
    /// - When:
    ///    - I invoke confirmSignUp with empty code
    /// - Then:
    ///    - I should get validation error.
    ///
    func testConfirmSignUpValidation() async throws {
        let username = "integTest\(UUID().uuidString)"

        do {
            _ = try await Amplify.Auth.confirmSignUp(for: username, confirmationCode: "")
            XCTFail("confirmSignUp with validation error should not succeed")
        } catch {
            guard case AuthError.validation = error else {
                XCTFail("Should return validation error")
                return
            }
        }
    }
}
