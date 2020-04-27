//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AuthenticationProviderAdapter {

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void) {

        // Password validation already completed in operation
        let password = request.password ?? ""

        let clientMetaData = (request.options.pluginOptions as? AWSAuthSignUpOptions)?.metadata ?? [:]
        let validationData = (request.options.pluginOptions as? AWSAuthSignUpOptions)?.validationData ?? [:]

        // Convert the attributes to [String: String]
        let attributes = request.options.userAttributes?.reduce(into: [String: String]()) {
            $0[$1.key.toString()] = $1.value
        }
        awsMobileClient.signUp(username: request.username,
                               password: password,
                               userAttributes: attributes ?? [:],
                               validationData: validationData,
                               clientMetaData: clientMetaData) { result, error in

                                guard error == nil else {
                                    let authError = AuthErrorHelper.toAmplifyAuthError(error!)
                                    completionHandler(.failure(authError))
                                    return
                                }

                                guard let result = result else {
                                    // This should not happen, return an unknown error.
                                    let error = AmplifyAuthError.unknown("Could not read result from signUp operation")
                                    completionHandler(.failure(error))
                                    return
                                }

                                var codeDeliveryDetails: AuthCodeDeliveryDetails?
                                if let deliveryDetails = result.codeDeliveryDetails {
                                    let destination = deliveryDetails.toDeliveryDestination()
                                    let attributeName = deliveryDetails.attributeName ?? ""
                                    codeDeliveryDetails = AuthCodeDeliveryDetails(destination: destination,
                                                                                  attributeName: attributeName)
                                }

                                let signUpStep: AuthSignUpStep = (result.signUpConfirmationState == .confirmed) ?
                                    .done : .confirmUser
                                let nextStep = AuthNextSignUpStep(signUpStep, codeDeliveryDetails: codeDeliveryDetails)
                                let signUpResult = AuthSignUpResult(nextStep)
                                completionHandler(.success(signUpResult))
        }
    }

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthConfirmSignUpOptions)?.metadata ?? [:]

        awsMobileClient.confirmSignUp(username: request.username,
                                      confirmationCode: request.code,
                                      clientMetaData: clientMetaData) { result, error in

                                        guard error == nil else {
                                            let authError = AuthErrorHelper.toAmplifyAuthError(error!)
                                            completionHandler(.failure(authError))
                                            return
                                        }

                                        guard result != nil else {
                                            // This should not happen, return an unknown error.
                                            let error = AmplifyAuthError.unknown("""
                                            Could not read result from confirmSignUp operation
                                            """)
                                            completionHandler(.failure(error))
                                            return
                                        }
                                        let nextStep = AuthNextSignUpStep(.done)
                                        let confirmSignUpResult = AuthSignUpResult(nextStep)
                                        completionHandler(.success(confirmSignUpResult))
        }
    }

    func resendSignUpCode(request: AuthResendSignUpCodeRequest,
                          completionHandler: @escaping (Result<AuthCodeDeliveryDetails, AmplifyAuthError>) -> Void) {

        awsMobileClient.resendSignUpCode(username: request.username) { result, error in
            guard error == nil else {
                let authError = AuthErrorHelper.toAmplifyAuthError(error!)
                completionHandler(.failure(authError))
                return
            }

            guard let result = result,
                let deliveryDetails = result.codeDeliveryDetails else {
                // This should not happen, return an unknown error.
                let error = AmplifyAuthError.unknown("Could not read result from resendSignUpCode operation")
                completionHandler(.failure(error))
                return
            }

            let destination = deliveryDetails.toDeliveryDestination()
            let attributeName = deliveryDetails.attributeName ?? ""
            let codeDeliveryDetails = AuthCodeDeliveryDetails(destination: destination,
                                                              attributeName: attributeName)
            completionHandler(.success(codeDeliveryDetails))
        }
    }
}
