//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

class AuthenticationProviderAdapter: AuthenticationProviderBehavior {

    let awsMobileClient: AWSMobileClientBehavior

    init(awsMobileClient: AWSMobileClientBehavior) {
        self.awsMobileClient = awsMobileClient
    }

    func signUp(request: AuthSignUpRequest,
                completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void) {

        awsMobileClient.signUp(username: request.username,
                               password: request.password,
                               userAttributes: request.options.userAttributes ?? [:],
                               validationData: request.options.validationData ?? [:],
                               clientMetaData: request.options.metadata ?? [:]) { result, error in

                                guard let result = result else {
                                    // TODO: Return signup error #172336364
                                    return
                                }
                                var codeDeliveryDetails: AuthCodeDeliveryDetails?
                                if let deliveryDetails = result.codeDeliveryDetails {
                                    let destination = deliveryDetails.destination ?? ""
                                    let deliveryMedium = deliveryDetails.deliveryMedium.toAmplifyDeliveryMedium()
                                    let attributeName = deliveryDetails.attributeName ?? ""
                                    codeDeliveryDetails = AuthCodeDeliveryDetails(destination: destination,
                                                                                 deliveryMedium: deliveryMedium,
                                                                                 attributeName: attributeName)
                                }
                                let isUserConfirmed = result.signUpConfirmationState == .confirmed
                                let signUpResult = AuthSignUpResult(userConfirmed: isUserConfirmed,
                                                                    codeDeliveryDetails: codeDeliveryDetails)
                                completionHandler(.success(signUpResult))
        }
    }

    func confirmSignUp(request: AuthConfirmSignUpRequest,
                       completionHandler: @escaping (Result<AuthSignUpResult, AmplifyAuthError>) -> Void) {
        // TODO: Complete implementation
    }
}

extension UserCodeDeliveryMedium {

    func toAmplifyDeliveryMedium() -> DeliveryMedium {
        switch self {
        case .email:
            return .email
        case .sms:
            return .sms
        case .unknown:
            return .unknown
        }
    }
}
