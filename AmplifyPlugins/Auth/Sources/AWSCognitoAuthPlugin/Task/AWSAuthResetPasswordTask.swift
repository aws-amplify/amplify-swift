//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

class AWSAuthResetPasswordTask: AuthResetPasswordTask {
    private let request: AuthResetPasswordRequest
    private let environment: AuthEnvironment
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.resetPasswordAPI
    }

    init(_ request: AuthResetPasswordRequest, environment: AuthEnvironment, authConfiguration: AuthConfiguration) {
        self.request = request
        self.environment = environment
        self.authConfiguration = authConfiguration
    }

    func execute() async throws -> AuthResetPasswordResult {
        if let validationError = request.hasError() {
            throw validationError
        }
        do {
            return try await resetPassword()
        } catch let error as ForgotPasswordOutputError {
            throw error.authError
        } catch let error as SdkError<ForgotPasswordOutputError> {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func resetPassword() async throws -> AuthResetPasswordResult {
        let userPoolEnvironment = try environment.userPoolEnvironment()
        let userPoolService = try userPoolEnvironment.cognitoUserPoolFactory()
        let clientMetaData = (request.options.pluginOptions
                              as? AWSAuthResetPasswordOptions)?.metadata ?? [:]

        let userPoolConfigurationData: UserPoolConfigurationData
        switch authConfiguration {
        case .userPools(let data):
            userPoolConfigurationData = data
        case .userPoolsAndIdentityPools(let data, _):
            userPoolConfigurationData = data
        case .identityPools:
            let error = AuthError.configuration("IdentityPool configuration is missing", AuthPluginErrorConstants.configurationError)
            throw error
        }
        let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
            for: request.username,
            credentialStoreClient: environment.credentialsClient)
        let encodedData = CognitoUserPoolASF.encodedContext(
            username: request.username,
            asfDeviceId: asfDeviceId,
            asfClient: environment.cognitoUserPoolASFFactory(),
            userPoolConfiguration: userPoolConfigurationData)
        let userContextData = CognitoIdentityProviderClientTypes.UserContextDataType(
            encodedData: encodedData)
        let analyticsMetadata = userPoolEnvironment
            .cognitoUserPoolAnalyticsHandlerFactory()
            .analyticsMetadata()
        let input = ForgotPasswordInput(
            analyticsMetadata: analyticsMetadata,
            clientId: userPoolConfigurationData.clientId,
            clientMetadata: clientMetaData,
            userContextData: userContextData,
            username: request.username)

        let result = try await userPoolService.forgotPassword(input: input)

        guard let deliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
            let authError = AuthError.unknown("Unable to get Auth code delivery details", nil)
            throw authError
        }
        let nextStep = AuthResetPasswordStep.confirmResetPasswordWithCode(deliveryDetails, [:])
        let authResetPasswordResult = AuthResetPasswordResult(isPasswordReset: false, nextStep: nextStep)
        return authResetPasswordResult
    }
}
