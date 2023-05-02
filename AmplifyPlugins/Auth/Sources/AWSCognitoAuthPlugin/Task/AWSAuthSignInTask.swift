//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInTask: AuthSignInTask, DefaultLogger {

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
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()
        //Check if we have a user pool configuration
        guard let userPoolConfiguration = authConfiguration.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

        try await validateCurrentState()

        let authflowType = authFlowType(userPoolConfiguration: userPoolConfiguration)
        do {
            log.verbose("Signing with \(authflowType)")
            let result = try await doSignIn(authflowType: authflowType)
            log.verbose("Received result")
            return result
        } catch {
            await waitForSignInCancel()
            throw error
        }
    }

    private func validateCurrentState() async throws {

        let stateSequences = await authStateMachine.listen()
        log.verbose("Validating current state")
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
            case .signingIn:
                log.verbose("Cancelling existing signIn flow")
                await sendCancelSignInEvent()
            case .signedOut:
                return
            default: continue
            }
        }
    }

    private func doSignIn(authflowType: AuthFlowType) async throws -> AuthSignInResult {
        let stateSequences = await authStateMachine.listen()
        log.verbose("Sending signIn event")
        await sendSignInEvent(authflowType: authflowType)
        log.verbose("Waiting for signin to complete")
        for await state in stateSequences {
            guard case .configured(let authNState,
                                   let authZState) = state else { continue }

            switch authNState {

            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else if case .error(let error) = authZState {
                    log.verbose("Authorization reached an error state \(error)")
                    throw error.authError
                }
            case .error(let error):
                throw error.authError

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

    private func sendCancelSignInEvent() async {
        let event = AuthenticationEvent(eventType: .cancelSignIn)
        await authStateMachine.send(event)
    }

    private func waitForSignInCancel() async {
        await sendCancelSignInEvent()
        let stateSequences = await authStateMachine.listen()
        log.verbose("Wait for signIn to cancel")
        for await state in stateSequences {
            guard case .configured(let authenticationState, _) = state else {
                continue
            }
            switch authenticationState {
            case .signedOut:
                return
            default: continue
            }
        }
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
