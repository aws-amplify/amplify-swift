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

class AWSAuthUpdateUserAttributesTask: AuthUpdateUserAttributesTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthUpdateUserAttributesRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.updateUserAttributesAPI
    }

    init(_ request: AuthUpdateUserAttributesRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
        do {
            let accessToken = try await getAccessToken()
            return try await updateUserAttribute(with: accessToken)
        } catch let error as UpdateUserAttributesOutputError {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.unknown("Unable to execute auth task", error)
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

    func updateUserAttribute(with accessToken: String) async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
        let clientMetaData = (request.options.pluginOptions as? AWSUpdateUserAttributesOptions)?.metadata ?? [:]
        let finalResult = try await UpdateAttributesOperationHelper.update(
            attributes: request.userAttributes,
            accessToken: accessToken,
            userPoolFactory: userPoolFactory,
            clientMetaData: clientMetaData)
        return finalResult
    }
}
