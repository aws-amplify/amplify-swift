//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin

class MockAuthUserServiceBehavior: AuthUserServiceBehavior {

    var interactions: [String] = []

    // swiftlint:disable line_length
    var fetchAttributesHandler: (AuthFetchUserAttributesRequest, FetchUserAttributesCompletion) -> Void = { _, completion in
        completion(.success([]))
    }

    func fetchAttributes(request: AuthFetchUserAttributesRequest,
                         completionHandler: @escaping FetchUserAttributesCompletion) {
        interactions.append(#function)
        fetchAttributesHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var updateAttributeHandler: (AuthUpdateUserAttributeRequest, UpdateUserAttributeCompletion) -> Void = { _, completion in
        completion(.success(AuthUpdateAttributeResult(isUpdated: true, nextStep: .done)))
    }

    func updateAttribute(request: AuthUpdateUserAttributeRequest,
                         completionHandler: @escaping UpdateUserAttributeCompletion) {
        interactions.append(#function)
        updateAttributeHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var updateAttributesHandler: (AuthUpdateUserAttributesRequest, UpdateUserAttributesCompletion) -> Void = { request, completion in
        let resultAsArray = request.userAttributes.map { attribute in
            return (attribute.key, AuthUpdateAttributeResult(isUpdated: true, nextStep: .done))
        }
        let resultAsDictionary = Dictionary(resultAsArray, uniquingKeysWith: { key, _ in key })
        completion(.success(resultAsDictionary))
    }

    func updateAttributes(request: AuthUpdateUserAttributesRequest,
                          completionHandler: @escaping UpdateUserAttributesCompletion) {
        interactions.append(#function)
        updateAttributesHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var resendAttributeConfirmationCodeHandler: (AuthAttributeResendConfirmationCodeRequest, ResendAttributeConfirmationCodeCompletion) -> Void = { _, completion in
        completion(.success(AuthCodeDeliveryDetails(destination: .email("user@example.com"))))
    }

    func resendAttributeConfirmationCode(request: AuthAttributeResendConfirmationCodeRequest,
                                         completionHandler: @escaping ResendAttributeConfirmationCodeCompletion) {
        interactions.append(#function)
        resendAttributeConfirmationCodeHandler(request, completionHandler)
    }

    // swiftlint:disable line_length
    var confirmAttributeHandler: (AuthConfirmUserAttributeRequest, ConfirmAttributeCompletion) -> Void = { _, completion in
        completion(.success(()))
    }

    func confirmAttribute(request: AuthConfirmUserAttributeRequest,
                          completionHandler: @escaping ConfirmAttributeCompletion) {
        interactions.append(#function)
        confirmAttributeHandler(request, completionHandler)
    }

    var changePasswordHandler: (AuthChangePasswordRequest, ChangePasswordCompletion) -> Void = { _, completion in
        completion(.success(()))
    }

    func changePassword(request: AuthChangePasswordRequest,
                        completionHandler: @escaping ChangePasswordCompletion) {
        interactions.append(#function)
        changePasswordHandler(request, completionHandler)
    }
}
