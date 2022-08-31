//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSCognitoIdentityProvider

class AWSAuthChangePasswordTask: AuthChangePasswordTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior
    
    private let request: AuthChangePasswordRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private var stateMachineToken: AuthStateMachineToken?
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.changePasswordAPI
    }

    init(_ request: AuthChangePasswordRequest,
         authStateMachine: AuthStateMachine,
         userPoolFactory: @escaping CognitoUserPoolFactory
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws {
        do {
            await didConfigure()
            let accessToken = try await getAccessToken()
            try await changePassword(with: accessToken)
        } catch let error as ChangePasswordOutputError {
            throw error.authError
        } catch let error {
            throw AuthError.configuration("Unable to execute auth task", AuthPluginErrorConstants.configurationError, error)
        }
    }
    
    private func didConfigure() async {
        await withCheckedContinuation { [weak self] (continuation: CheckedContinuation<Void, Never>) in
            stateMachineToken = authStateMachine.listen({ [weak self] state in
                guard let self = self, case .configured = state else { return }
                self.authStateMachine.cancel(listenerToken: self.stateMachineToken!)
                continuation.resume()
            }, onSubscribe: {})
        }
    }

    private func getAccessToken() async throws -> String {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            fetchAuthSessionHelper.fetch(authStateMachine) { result in
                switch result {
                case .success(let session):
                    guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider,
                          let tokens = try? cognitoTokenProvider.getCognitoTokens().get() else {
                        continuation.resume(throwing: AuthError.unknown("Unable to fetch auth session", nil))
                        return
                    }
                    continuation.resume(returning: tokens.accessToken)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func changePassword(with accessToken: String) async throws {
        let userPoolService = try userPoolFactory()
        let input = ChangePasswordInput(accessToken: accessToken, previousPassword: request.oldPassword, proposedPassword: request.newPassword)
        _ = try await userPoolService.changePassword(input: input)
    }
}
