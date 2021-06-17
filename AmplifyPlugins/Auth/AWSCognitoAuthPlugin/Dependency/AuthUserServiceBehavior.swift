//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

typealias FetchUserAttributesCompletion = (Result<[AuthUserAttribute], AuthError>) -> Void

typealias UpdateUserAttributeCompletion = (Result<AuthUpdateAttributeResult, AuthError>) -> Void

typealias UpdateUserAttributesCompletion = (Result<[AuthUserAttributeKey: AuthUpdateAttributeResult],
    AuthError>) -> Void

// swiftlint:disable:next type_name
typealias ResendAttributeConfirmationCodeCompletion = (Result<AuthCodeDeliveryDetails,
    AuthError>) -> Void

typealias ConfirmAttributeCompletion = (Result<Void, AuthError>) -> Void

typealias ChangePasswordCompletion = (Result<Void, AuthError>) -> Void

protocol AuthUserServiceBehavior: AnyObject {

    func fetchAttributes(request: AuthFetchUserAttributesRequest,
                         completionHandler: @escaping FetchUserAttributesCompletion)

    func updateAttribute(request: AuthUpdateUserAttributeRequest,
                         completionHandler: @escaping UpdateUserAttributeCompletion)

    func updateAttributes(request: AuthUpdateUserAttributesRequest,
                          completionHandler: @escaping UpdateUserAttributesCompletion)

    func resendAttributeConfirmationCode(request: AuthAttributeResendConfirmationCodeRequest,
                                         completionHandler: @escaping ResendAttributeConfirmationCodeCompletion)

    func confirmAttribute(request: AuthConfirmUserAttributeRequest,
                          completionHandler: @escaping ConfirmAttributeCompletion)

    func changePassword(request: AuthChangePasswordRequest,
                        completionHandler: @escaping ChangePasswordCompletion)
}
