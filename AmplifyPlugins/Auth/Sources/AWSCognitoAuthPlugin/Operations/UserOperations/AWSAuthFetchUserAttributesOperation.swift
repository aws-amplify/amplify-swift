//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

public class AWSAuthFetchUserAttributesOperation: AmplifyOperation<
AuthFetchUserAttributesRequest,
[AuthUserAttribute],
AuthError>, AuthFetchUserAttributeOperation {
    
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    private let authStateMachine: AuthStateMachine
    private let credentialStoreStateMachine: CredentialStoreStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private var statelistenerToken: AuthStateMachineToken?
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    init(_ request: AuthFetchUserAttributesRequest,
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
                    await self?.getUserAttributes(with: tokens.accessToken)
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }
        
    }
    
    func getUserAttributes(with accessToken: String) async {
        
        do {
            let userPoolService = try userPoolFactory()

            let input = GetUserInput(accessToken: accessToken)
            
            let result = try await userPoolService.getUser(input: input)
            
            if self.isCancelled {
                return
            }
            
            guard let attributes = result.userAttributes else {
                let authError = AuthError.service("Unable to get Auth code delivery details",
                                                  AmplifyErrorMessages.shouldNotHappenReportBugToAWS(),
                                                  nil)
                self.dispatch(authError)
                return
            }
            
            let mappedAttributes: [AuthUserAttribute] = attributes.compactMap { oldAttribute in
                guard let attributeName = oldAttribute.name,
                      let attributeValue = oldAttribute.value else {
                    return nil
                }
                return AuthUserAttribute(AuthUserAttributeKey(rawValue: attributeName),
                                         value: attributeValue)
            }
            
            self.dispatch(mappedAttributes)
        }
        catch let error as GetUserOutputError {
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
    
    private func dispatch(_ result: [AuthUserAttribute]) {
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
