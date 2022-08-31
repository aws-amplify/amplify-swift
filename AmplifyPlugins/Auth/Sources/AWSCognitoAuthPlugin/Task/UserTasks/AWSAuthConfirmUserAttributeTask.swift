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

class AWSAuthConfirmUserAttributeTask: AuthConfirmUserAttributeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthConfirmUserAttributeRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmUserAttributesAPI
    }

    init(_ request: AuthConfirmUserAttributeRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws {
        do {
            let accessToken = try await getAccessToken()
            try await confirmUserAttribute(with: accessToken)
        } catch let error as VerifyUserAttributeOutputError {
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

    func confirmUserAttribute(with accessToken: String) async throws {
        let userPoolService = try userPoolFactory()

        let input = VerifyUserAttributeInput(
            accessToken: accessToken,
            attributeName: request.attributeKey.rawValue,
            code: request.confirmationCode)

        _ = try await userPoolService.verifyUserAttribute(input: input)
    }
}
