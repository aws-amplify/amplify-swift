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
            let result = try await Amplify.Auth.resendSignUpCode(for: "user-non-exists")

            // App clients with "Prevent user existence errors" enabled will return a simulated result
            // https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-pool-managing-errors.html#cognito-user-pool-managing-errors-password-reset
            // Gen2 configuration is enabled with Prevent User existence errors, while Gen1 backend is not.
            if useGen2Configuration {
                guard case .email = result.destination else {
                    XCTFail("Expected email detination in result, result: \(result)")
                    return
                }
            } else {
                XCTFail("resendSignUpCode with non existing user should not return result, result returned: \(result)")
            }
        } catch let error as AuthError {
            let underlyingError = error.underlyingError as? AWSCognitoAuthError
            switch underlyingError {
            case .userNotFound, .limitExceeded: break
            default:
                XCTFail(
                    """
                    Expected AWSCognitoAuthError.userNotFound || AWSCognitoAuthError.limitExceed
                    Recevied: \(error)
                    """
                )
            }
        } catch {
            XCTFail("Expected `AuthError` - received: \(error)")
        }
    }
}
