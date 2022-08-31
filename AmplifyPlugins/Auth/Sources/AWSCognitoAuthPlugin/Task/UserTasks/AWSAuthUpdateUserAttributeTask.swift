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

class AWSAuthUpdateUserAttributeTask: AuthUpdateUserAttributeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthUpdateUserAttributeRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private var stateMachineToken: AuthStateMachineToken?
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.updateUserAttributeAPI
    }

    init(_ request: AuthUpdateUserAttributeRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws -> AuthUpdateAttributeResult {
        do {
            await didConfigure()
            let accessToken = try await getAccessToken()
            return try await updateUserAttribute(with: accessToken)
        } catch let error as UpdateUserAttributesOutputError {
            throw error.authError
        } catch let error as AuthError {
            dispatch(result: .failure(error))
            throw error
        } catch let error {
            let error = AuthError.unknown("Unable to execute auth task", error)
            throw error
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
                    guard let cognitoTokenProvider = session as? AuthCognitoTokensProvider else {
                        continuation.resume(throwing: AuthError.unknown("Unable to fetch auth session", nil))
                        return
                    }

                    do {
                        let tokens = try cognitoTokenProvider.getCognitoTokens().get()
                        continuation.resume(returning: tokens.accessToken)
                    } catch let error as AuthError {
                        continuation.resume(throwing: error)
                    } catch {
                        continuation.resume(throwing:AuthError.unknown("Unable to fetch auth session", error))
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func updateUserAttribute(with accessToken: String) async throws -> AuthUpdateAttributeResult {
        let clientMetaData = (request.options.pluginOptions as? AWSUpdateUserAttributeOptions)?.metadata ?? [:]

        let finalResult = try await UpdateAttributesOperationHelper.update(
            attributes: [request.userAttribute],
            accessToken: accessToken,
            userPoolFactory: userPoolFactory,
            clientMetaData: clientMetaData)

        guard let attributeResult = finalResult[request.userAttribute.key] else {
            let authError = AuthError.unknown("Attribute to be updated does not exist in the result", nil)
            throw authError
        }

        return attributeResult
    }
}
