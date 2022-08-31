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

class AWSAuthAttributeResendConfirmationCodeTask: AuthAttributeResendConfirmationCodeTask {
    typealias CognitoUserPoolFactory = () throws -> CognitoUserPoolBehavior

    private let request: AuthAttributeResendConfirmationCodeRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: CognitoUserPoolFactory
    private let fetchAuthSessionHelper: FetchAuthSessionOperationHelper
    private var stateMachineToken: AuthStateMachineToken?
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.attributeResendConfirmationCodeAPI
    }

    init(_ request: AuthAttributeResendConfirmationCodeRequest, authStateMachine: AuthStateMachine, userPoolFactory: @escaping CognitoUserPoolFactory) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.fetchAuthSessionHelper = FetchAuthSessionOperationHelper()
    }

    func execute() async throws -> AuthCodeDeliveryDetails {
        do {
            await didConfigure()
            let accessToken = try await getAccessToken()
            let devices = try await initiateGettingVerificationCode(with: accessToken)
            return devices
        } catch let error as GetUserAttributeVerificationCodeOutputError {
            throw error.authError
        } catch let error as AuthError {
            throw error
        } catch let error {
            throw AuthError.configuration("Unable to execute auth task",
                                          AuthPluginErrorConstants.configurationError,
                                          error)
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

    func initiateGettingVerificationCode(with accessToken: String) async throws -> AuthCodeDeliveryDetails {
        let userPoolService = try userPoolFactory()
        let clientMetaData = (request.options.pluginOptions as? AWSAttributeResendConfirmationCodeOptions)?.metadata ?? [:]

        let input = GetUserAttributeVerificationCodeInput(
            accessToken: accessToken,
            attributeName: request.attributeKey.rawValue,
            clientMetadata: clientMetaData)

        let result = try await userPoolService.getUserAttributeVerificationCode(input: input)
        guard let deliveryDetails = result.codeDeliveryDetails?.toAuthCodeDeliveryDetails() else {
            let authError = AuthError.unknown("Unable to get Auth code delivery details", nil)
            throw authError
        }
        return deliveryDetails
    }
}
