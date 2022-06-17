//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

public class AWSAuthConfirmUserAttributeOperation: AmplifyOperation<
AuthConfirmUserAttributeRequest,
Void,
AuthError>, AuthConfirmUserAttributeOperation {

    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let authStateMachine: AuthStateMachine
    private let credentialStoreStateMachine: CredentialStoreStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private var statelistenerToken: AuthStateMachineToken?
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper

    init(_ request: AuthConfirmUserAttributeRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory,
         resultListener: ResultListener?) {
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmUserAttributesAPI,
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
                    await self?.confirmUserAttribute(with: tokens.accessToken)
                }
            case .failure(let error):
                self?.dispatch(error)
            }
        }

    }

    func confirmUserAttribute(with accessToken: String) async {

        do {
            let userPoolService = try userPoolFactory()

            let input = VerifyUserAttributeInput(
                accessToken: accessToken,
                attributeName: request.attributeKey.rawValue,
                code: request.confirmationCode)

            _ = try await userPoolService.verifyUserAttribute(input: input)

            self.dispatch()
        } catch let error as VerifyUserAttributeOutputError {
            self.dispatch(error.authError)
        } catch let error {
            let error = AuthError.configuration(
                "Unable to create a Swift SDK user pool service",
                AuthPluginErrorConstants.configurationError,
                error)
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
