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

public class AWSAuthResendSignUpCodeOperation:
    AmplifyOperation< AuthResendSignUpCodeRequest, AuthCodeDeliveryDetails, AuthError>, AuthResendSignUpCodeOperation {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    private let userPoolFactory: CognitoUserPoolFactory
    private var authConfiguration: AuthConfiguration
    
    init(_ request: AuthResendSignUpCodeRequest,
         userPoolFactory: @escaping CognitoUserPoolFactory,
         authConfiguration: AuthConfiguration,
         resultListener: ResultListener?)
    {
        self.userPoolFactory = userPoolFactory
        self.authConfiguration = authConfiguration
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resendSignUpCodeAPI,
                   request: request,
                   resultListener: resultListener)
    }
    
    override public func main() {
        if isCancelled {
            finish()
            return
        }
        
        Task.init { [weak self] in
            await self?.resendSignUpCode()
        }
    }
    
    func resendSignUpCode() async {
        do {
            let userPoolService = try userPoolFactory()
            let clientMetaData = (request.options.pluginOptions
                                  as? AWSResendSignUpCodeOptions)?.metadata ?? [:]
            
            let userPoolConfigurationData : UserPoolConfigurationData
            switch authConfiguration {
            case .userPools(let data):
                userPoolConfigurationData = data
            case .userPoolsAndIdentityPools(let data, _):
                userPoolConfigurationData = data
            case .identityPools:
                let error = AuthError.configuration("UserPool configuration is invalid", AuthPluginErrorConstants.configurationError)
                throw error
            }
            
            let input = ResendConfirmationCodeInput(clientId: userPoolConfigurationData.clientId,
                                                    clientMetadata: clientMetaData,
                                                    username: request.username)
            
            let result = try await userPoolService.resendConfirmationCode(input: input)
            
            if self.isCancelled {
                return
            }
            
            guard let deliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
                let authError = AuthError.unknown("Unable to get Auth code delivery details",
                                                  nil)
                self.dispatch(authError)
                return
            }
            self.dispatch(deliveryDetails)
        }
        catch let error as SdkError<ResendConfirmationCodeOutputError> {
            self.dispatch(error.authError)
        }
        catch let error {
            let error = AuthError.configuration(
                "Unable to create a Swift SDK user pool service",
                AuthPluginErrorConstants.configurationError,
                error)
            self.dispatch(error)
        }
    }
    
    private func dispatch(_ result: AuthCodeDeliveryDetails) {
        let result = OperationResult.success(result)
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
