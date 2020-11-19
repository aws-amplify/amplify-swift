//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthUserServiceBehavior: AuthUserServiceBehavior {
    func fetchAttributes(request: AuthFetchUserAttributesRequest,
                         completionHandler: @escaping FetchUserAttributesCompletion) {
        // Incomplete implementation
    }

    func updateAttribute(request: AuthUpdateUserAttributeRequest,
                         completionHandler: @escaping UpdateUserAttributeCompletion) {
        // Incomplete implementation
    }

    func updateAttributes(request: AuthUpdateUserAttributesRequest,
                          completionHandler: @escaping UpdateUserAttributesCompletion) {
        // Incomplete implementation
    }

    func resendAttributeConfirmationCode(request: AuthAttributeResendConfirmationCodeRequest,
                                         completionHandler: @escaping ResendAttributeConfirmationCodeCompletion) {
        // Incomplete implementation
    }

    func confirmAttribute(request: AuthConfirmUserAttributeRequest,
                          completionHandler: @escaping ConfirmAttributeCompletion) {
        // Incomplete implementation
    }

    func changePassword(request: AuthChangePasswordRequest,
                        completionHandler: @escaping ChangePasswordCompletion) {
        // Incomplete implementation
    }


}
