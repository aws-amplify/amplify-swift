//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension AuthenticationProviderAdapter {

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AuthError>) -> Void ) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthResetPasswordOptions)?.metadata ?? [:]
        awsMobileClient.forgotPassword(
            username: request.username,
            clientMetaData: clientMetaData) { result, error in
                if let error = error {
                    let authError = AuthErrorHelper.toAuthError(error)
                    completionHandler(.failure(authError))
                    return
                }
                guard let result = result else {
                    // This should not happen, return an unknown error.
                    let error = AuthError.unknown("Could not read result from resetPassword operation")
                    completionHandler(.failure(error))
                    return
                }

                // Expecting the api to return a codeDeliveryDetail always. If we couldnot find the delivery
                // details return an unknown error
                guard let codeDeliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
                    let error = AuthError.unknown("""
                    Could not read delivery details for the confirmation code from resetPassword result.
                    """)
                    completionHandler(.failure(error))
                    return
                }

                let nextStep = AuthResetPasswordStep.confirmResetPasswordWithCode(codeDeliveryDetails, nil)
                let authResetPasswordResult = AuthResetPasswordResult(isPasswordReset: false, nextStep: nextStep)
                completionHandler(.success(authResetPasswordResult))
        }
    }

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AuthError>) -> Void) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthConfirmResetPasswordOptions)?.metadata ?? [:]
        awsMobileClient.confirmForgotPassword(
            username: request.username,
            newPassword: request.newPassword,
            confirmationCode: request.confirmationCode,
            clientMetaData: clientMetaData) { _, error in
                if let error = error {
                    let authError = AuthErrorHelper.toAuthError(error)
                    completionHandler(.failure(authError))
                    return
                }
                completionHandler(.success(()))
        }
    }
}
