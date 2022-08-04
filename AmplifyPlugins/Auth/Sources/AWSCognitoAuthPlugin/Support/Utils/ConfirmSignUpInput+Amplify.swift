//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

extension ConfirmSignUpInput {
    init(username: String,
         confirmationCode: String,
         asfDeviceId: String? = nil,
         environment: UserPoolEnvironment
    ) {

        let configuration = environment.userPoolConfiguration
        let secretHash = Self.calculateSecretHash(
            username: username,
            userPoolConfiguration: configuration)
        var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
        if let asfDeviceId = asfDeviceId,
           let encodedData = CognitoUserPoolASF.encodedContext(
            username: username,
            asfDeviceId: asfDeviceId,
            asfClient: environment.cognitoUserPoolASFFactory(),
            userPoolConfiguration: environment.userPoolConfiguration) {
            userContextData = .init(encodedData: encodedData)
        }
        self.init(
            clientId: configuration.clientId,
            confirmationCode: confirmationCode,
            secretHash: secretHash,
            userContextData: userContextData, username: username)
    }

    private static func calculateSecretHash(
        username: String,
        userPoolConfiguration: UserPoolConfigurationData) -> String? {
            let userPoolClientId = userPoolConfiguration.clientId
            if let clientSecret = userPoolConfiguration.clientSecret {

                return SRPSignInHelper.clientSecretHash(
                    username: username,
                    userPoolClientId: userPoolClientId,
                    clientSecret: clientSecret
                )
            }
            return nil
        }
}
