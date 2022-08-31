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

class AWSAuthFetchUserAttributeTask: AuthFetchUserAttributeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthFetchUserAttributesRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.fetchUserAttributesAPI
    }

    init(_ request: AuthFetchUserAttributesRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws -> [AuthUserAttribute] {
        do {
            let accessToken = try await getAccessToken()
            return try await getUserAttributes(with: accessToken)
        } catch let error as GetUserOutputError {
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

    func getUserAttributes(with accessToken: String) async throws -> [AuthUserAttribute] {
        let userPoolService = try userPoolFactory()
        let input = GetUserInput(accessToken: accessToken)
        let result = try await userPoolService.getUser(input: input)

        guard let attributes = result.userAttributes else {
            let authError = AuthError.unknown("Unable to get Auth code delivery details", nil)
            throw authError
        }

        let mappedAttributes: [AuthUserAttribute] = attributes.compactMap { oldAttribute in
            guard let attributeName = oldAttribute.name,
                  let attributeValue = oldAttribute.value else {
                return nil
            }
            return AuthUserAttribute(AuthUserAttributeKey(rawValue: attributeName),
                                     value: attributeValue)
        }
        return mappedAttributes
    }

}
