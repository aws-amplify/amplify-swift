//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

extension AuthenticationProviderAdapter {

    func resetPassword(request: AuthResetPasswordRequest,
                       completionHandler: @escaping (Result<AuthResetPasswordResult, AmplifyAuthError>) -> Void ) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthResetPasswordOptions)?.metadata ?? [:]
        awsMobileClient.forgotPassword(
            username: request.username,
            clientMetaData: clientMetaData) { result, error in
                if let error = error {
                    let authError = AuthErrorHelper.toAmplifyAuthError(error)
                    completionHandler(.failure(authError))
                    return
                }
                guard let result = result else {
                    // This should not happen, return an unknown error.
                    let error = AmplifyAuthError.unknown("Could not read result from resetPassword operation")
                    completionHandler(.failure(error))
                    return
                }

                // If there is no codeDeliveryDetails, there is no next step. On the other hand if there is
                // codeDeliveryDetails, it means that the next step is to confirmResetPassword.
                guard let codeDeliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
                    let authResetPasswordResult = AuthResetPasswordResult(isPasswordReset: true, nextStep: .done)
                    completionHandler(.success(authResetPasswordResult))
                    return
                }

                let nextStep = AuthResetPasswordStep.confirmResetPasswordWithCode(codeDeliveryDetails, nil)
                let authResetPasswordResult = AuthResetPasswordResult(isPasswordReset: false, nextStep: nextStep)
                completionHandler(.success(authResetPasswordResult))
        }
    }

    func confirmResetPassword(request: AuthConfirmResetPasswordRequest,
                              completionHandler: @escaping (Result<Void, AmplifyAuthError>) -> Void) {

        let clientMetaData = (request.options.pluginOptions as? AWSAuthConfirmResetPasswordOptions)?.metadata ?? [:]
        awsMobileClient.confirmForgotPassword(
            username: request.username,
            newPassword: request.newPassword,
            confirmationCode: request.confirmationCode,
            clientMetaData: clientMetaData) { _, error in
                if let error = error {
                    let authError = AuthErrorHelper.toAmplifyAuthError(error)
                    completionHandler(.failure(authError))
                    return
                }
                completionHandler(.success(()))
        }
    }
}
