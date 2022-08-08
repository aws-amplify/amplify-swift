//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import ClientRuntime
import AWSCognitoIdentityProvider

public class AWSAuthConfirmResetPasswordOperation: AmplifyOperation<
AuthConfirmResetPasswordRequest,
Void,
AuthError>, AuthConfirmResetPasswordOperation {

    private let environment: AuthEnvironment
    private var authConfiguration: AuthConfiguration

    init(_ request: AuthConfirmResetPasswordRequest,
         environment: AuthEnvironment,
         authConfiguration: AuthConfiguration,
         resultListener: ResultListener?) {
        self.environment = environment
        self.authConfiguration = authConfiguration
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmResetPasswordAPI,
                   request: request,
                   resultListener: resultListener)
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }

        if let validationError = request.hasError() {
            dispatch(validationError)
            finish()
            return
        }

        Task.init { [weak self] in
            await self?.confirmResetPassword(authEnvironment: environment)
        }
    }

    func confirmResetPassword(authEnvironment: AuthEnvironment) async {
        do {
            let userPoolService = try authEnvironment.cognitoUserPoolFactory()
            let clientMetaData = (request.options.pluginOptions
                                  as? AWSResendSignUpCodeOptions)?.metadata ?? [:]

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
                credentialStoreClient: authEnvironment.credentialStoreClientFactory())
            let encodedData = CognitoUserPoolASF.encodedContext(
                username: request.username,
                asfDeviceId: asfDeviceId,
                asfClient: authEnvironment.cognitoUserPoolASFFactory(),
                userPoolConfiguration: userPoolConfigurationData)
            let userContextData = CognitoIdentityProviderClientTypes.UserContextDataType(
                encodedData: encodedData)

            let input = ConfirmForgotPasswordInput(clientId: userPoolConfigurationData.clientId,
                                                   clientMetadata: clientMetaData,
                                                   confirmationCode: request.confirmationCode,
                                                   password: request.newPassword, userContextData: userContextData,
                                                   username: request.username)

            _ = try await userPoolService.confirmForgotPassword(input: input)

            if self.isCancelled {
                finish()
                return
            }

            self.dispatch()
        } catch let error as ConfirmForgotPasswordOutputError {
            self.dispatch(error.authError)
        } catch let error as SdkError<ConfirmForgotPasswordOutputError> {
            self.dispatch(error.authError)
        } catch let error as AuthError {
            self.dispatch(error)
        } catch let error {
            let error = AuthError.unknown("Unable to create a Swift SDK user pool service", error)
            self.dispatch(error)
        }
    }

    private func dispatch() {
        let result = OperationResult.success(())
        dispatch(result: result)
        finish()
    }

    private func dispatch(_ error: AuthError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
        Amplify.log.error(error: error)
        finish()
    }
}
