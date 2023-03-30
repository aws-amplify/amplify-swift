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
         clientMetadata: [String: String]?,
         asfDeviceId: String?,
         environment: UserPoolEnvironment
    ) {

        let configuration = environment.userPoolConfiguration
        let secretHash = ClientSecretHelper.calculateSecretHash(
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
        let analyticsMetadata = environment
            .cognitoUserPoolAnalyticsHandlerFactory()
            .analyticsMetadata()
        self.init(
            analyticsMetadata: analyticsMetadata,
            clientId: configuration.clientId,
            clientMetadata: clientMetadata,
            confirmationCode: confirmationCode,
            secretHash: secretHash,
            userContextData: userContextData,
            username: username)
    }
}
