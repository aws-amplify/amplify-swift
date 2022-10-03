//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInTask: AuthSignInTask {

    private let request: AuthSignInRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInAPI
    }

    init(_ request: AuthSignInRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
    }

    func execute() async throws -> AuthSignInResult {
        guard let userPoolConfiguration = authConfiguration.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthenticationError.configuration(message: message)
            throw authError
        }

        await taskHelper.didStateMachineConfigured()
        try await validateCurrentState()

        let authflowType = authFlowType(userPoolConfiguration: userPoolConfiguration)
        return try await doSignIn(authflowType: authflowType)
    }

    private func validateCurrentState() async throws {

        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }

            switch authenticationState {
            case .signedIn:
                let error = AuthError.invalidState(
                    "There is already a user in signedIn state. SignOut the user first before calling signIn",
                    AuthPluginErrorConstants.invalidStateError, nil)
                throw error
            case .signedOut:
                return
            default: continue
            }
        }
    }

    private func doSignIn(authflowType: AuthFlowType) async throws -> AuthSignInResult {
        let stateSequences = await authStateMachine.listen()
        await sendSignInEvent(authflowType: authflowType)
        for await state in stateSequences {
            guard case .configured(let authNState,
                                   let authZState) = state else { continue }

            switch authNState {

            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else if case .error(let error) = authZState {
                    let error = AuthError.unknown("Sign in reached an error state", error)
                    throw error
                }
            case .error(let error):
                let error = AuthError.unknown("Sign in reached an error state", error)
                throw error

            case .signingIn(let signInState):
                guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                    continue
                }
                return result
            default:
                continue
            }
        }
        throw AuthError.unknown("Sign in reached an error state")
    }

    private func sendSignInEvent(authflowType: AuthFlowType) async {
        let signInData = SignInEventData(
            username: request.username,
            password: request.password,
            clientMetadata: clientMetadata(),
            signInMethod: .apiBased(authflowType)
        )
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        await authStateMachine.send(event)
    }

    private func authFlowType(userPoolConfiguration: UserPoolConfigurationData) -> AuthFlowType {

        if let flowType = (request.options.pluginOptions as? AWSAuthSignInOptions)?.authFlowType {
            return flowType
        }
        return userPoolConfiguration.authFlowType
    }

    private func clientMetadata() -> [String: String] {

        let pluginOptions = request.options.pluginOptions as? AWSAuthSignInOptions

        // Since InitiateAuth API explicitly doesn't accept validationData,
        // we can pass this data to the Lambda function by using the ClientMetadata parameter
        var clientMetadata = pluginOptions?.metadata ?? [:]
        for (key, value) in pluginOptions?.validationData ?? [:] {
            clientMetadata[key] = value
        }
        return clientMetadata
    }
}
