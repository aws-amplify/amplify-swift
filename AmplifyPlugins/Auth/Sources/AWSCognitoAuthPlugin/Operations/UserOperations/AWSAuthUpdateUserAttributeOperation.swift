//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

public class AWSAuthUpdateUserAttributeOperation: AmplifyOperation<
AuthUpdateUserAttributeRequest,
AuthUpdateAttributeResult,
AuthError>, AuthUpdateUserAttributeOperation {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    private let authStateMachine: AuthStateMachine
    private let credentialStoreStateMachine: CredentialStoreStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private var statelistenerToken: AuthStateMachineToken?
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    init(_ request: AuthUpdateUserAttributeRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory,
         resultListener: ResultListener?)
    {
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchUserAttributesAPI,
                   request: request,
                   resultListener: resultListener)
    }
    
    override public func main() {
        if isCancelled {
            finish()
            return
        }
        
        fetchAuthSessionHelper.fetch(authStateMachine) { [weak self] result in
            switch result {
            case .success(let session):
                guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider,
                      let tokens = try? cognitoTokenProvider.getCognitoTokens().get() else {
                    self?.dispatch(AuthError.unknown("Unable to fetch auth session", nil))
                    return
                }
                Task.init { [weak self] in
                    await self?.updateAttribute(with: tokens.accessToken)
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }
        
    }
    
    func updateAttribute(with accessToken: String) async {
        
        do {
            let clientMetaData = (request.options.pluginOptions as? AWSUpdateUserAttributeOptions)?.metadata ?? [:]
            
            let finalResult = try await UpdateAttributesOperationHelper.update(
                attributes: [request.userAttribute],
                accessToken: accessToken,
                userPoolFactory: userPoolFactory,
                clientMetaData: clientMetaData)
            
            guard let dispatchResult = finalResult[request.userAttribute.key] else {
                let authError = AuthError.service("Attribute to be updated does not exist in the result",
                                                  AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                                                  nil)
                self.dispatch(authError)
                return
            }
            
            dispatch(dispatchResult)
        }
        catch let error as UpdateUserAttributesOutputError {
            self.dispatch(error.authError)
        }
        catch let error as AuthError {
            self.dispatch(error)
        }
        catch let error {
            let error = AuthError.configuration(
                "Unable to create a Swift SDK user pool service",
                AuthPluginErrorConstants.configurationError,
                error)
            self.dispatch(error)
        }
    }
    
    private func dispatch(_ result: AuthUpdateAttributeResult) {
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
