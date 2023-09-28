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

class AWSAuthResendSignUpCodeTask: AuthResendSignUpCodeTask, DefaultLogger {
    private let request: AuthResendSignUpCodeRequest
    private let environment: AuthEnvironment
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.resendSignUpCodeAPI
    }

    init(_ request: AuthResendSignUpCodeRequest, environment: AuthEnvironment, authConfiguration: AuthConfiguration) {
        self.request = request
        self.environment = environment
        self.authConfiguration = authConfiguration
    }

    func execute() async throws -> AuthCodeDeliveryDetails {
        log.verbose("Starting execution")
        if let validationError = request.hasError() {
            throw validationError
        }

        do {
            let details = try await resendSignUpCode()
            log.verbose("Received result")
            return details
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            throw AuthError.unknown("Unable to execute auth task", error)
        }
    }

    func resendSignUpCode() async throws -> AuthCodeDeliveryDetails {
        let userPoolEnvironment = try environment.userPoolEnvironment()
        let userPoolService = try userPoolEnvironment.cognitoUserPoolFactory()
        let clientMetaData = (request.options.pluginOptions as? AWSAuthResendSignUpCodeOptions)?.metadata ?? [:]

        let userPoolConfigurationData: UserPoolConfigurationData
        switch authConfiguration {
        case .userPools(let data):
            userPoolConfigurationData = data
        case .userPoolsAndIdentityPools(let data, _):
            userPoolConfigurationData = data
        case .identityPools:
            let error = AuthError.configuration("UserPool configuration is missing", AuthPluginErrorConstants.configurationError)
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
        let secretHash = ClientSecretHelper.calculateSecretHash(
            username: request.username,
            userPoolConfiguration: userPoolConfigurationData
        )
        let input = ResendConfirmationCodeInput(
            analyticsMetadata: analyticsMetadata,
            clientId: userPoolConfigurationData.clientId,
            clientMetadata: clientMetaData,
            secretHash: secretHash,
            userContextData: userContextData,
            username: request.username)

        let result = try await userPoolService.resendConfirmationCode(input: input)

        guard let deliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
            let error = AuthError.unknown("Unable to get Auth code delivery details", nil)
            throw error
        }

        return deliveryDetails
    }
    
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}
