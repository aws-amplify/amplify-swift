//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthenticationProviderAdapter {

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {

        // Password validation already completed in operation
        let password = request.password ?? ""

        let clientMetaData = (request.options.pluginOptions as? AWSAuthSignUpOptions)?.metadata ?? [:]
        let validationData = (request.options.pluginOptions as? AWSAuthSignUpOptions)?.validationData ?? [:]

        // Convert the attributes to [String: String]
        let attributes = request.options.userAttributes?.reduce(into: [String: String]()) {
            $0[$1.key.rawValue] = $1.value
        }
        awsMobileClient.signUp(username: request.username,
                               password: password,
                               userAttributes: attributes ?? [:],
                               validationData: validationData,
                               clientMetaData: clientMetaData) { result, error in

                                guard error == nil else {
                                    let authError = AuthErrorHelper.toAuthError(error!)
                                    completionHandler(.failure(authError))
                                    return
                                }

                                guard let result = result else {
                                    // This should not happen, return an unknown error.
                                    let error = AuthError.unknown("""
                                    Could not read result from signUp operation. The operation did not return any error
                                    or result from the api.
                                    """)
                                    completionHandler(.failure(error))
                                    return
                                }

                                let codeDeliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails()
                                let nextStep: AuthSignUpStep = (result.signUpConfirmationState == .confirmed) ?
                                    .done : .confirmUser(codeDeliveryDetails, nil)
                                let signUpResult = AuthSignUpResult(nextStep)
                                completionHandler(.success(signUpResult))
        }
    }

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AuthError>) -> Void) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthConfirmSignUpOptions)?.metadata ?? [:]

        awsMobileClient.confirmSignUp(username: request.username,
                                      confirmationCode: request.code,
                                      clientMetaData: clientMetaData) { result, error in

                                        guard error == nil else {
                                            let authError = AuthErrorHelper.toAuthError(error!)
                                            completionHandler(.failure(authError))
                                            return
                                        }

                                        guard result != nil else {
                                            // This should not happen, return an unknown error.
                                            let error = AuthError.unknown("""
                                            Could not read result from confirmSignUp operation
                                            """)
                                            completionHandler(.failure(error))
                                            return
                                        }
                                        let confirmSignUpResult = AuthSignUpResult(.done)
                                        completionHandler(.success(confirmSignUpResult))
        }
    }

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AuthError>) -> Void) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthResendSignUpCodeOptions)?.metadata ?? [:]

        awsMobileClient.resendSignUpCode(username: request.username, clientMetaData: clientMetaData) { result, error in
            guard error == nil else {
                let authError = AuthErrorHelper.toAuthError(error!)
                completionHandler(.failure(authError))
                return
            }

            guard let result = result,
                let deliveryDetails = result.codeDeliveryDetails else {
                    // This should not happen, return an unknown error.
                    let error = AuthError.unknown("Could not read result from resendSignUpCode operation")
                    completionHandler(.failure(error))
                    return
            }
            let codeDeliveryDetails = deliveryDetails.toAuthCodeDeliveryDetails()
            completionHandler(.success(codeDeliveryDetails))
        }
    }
}
