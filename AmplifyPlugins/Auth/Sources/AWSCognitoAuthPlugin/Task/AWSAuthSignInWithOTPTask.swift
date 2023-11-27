//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInWithOTPTask: AuthSignInWithOTPTask, DefaultLogger {

    private let request: AuthSignInWithOTPRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithOTPAPI
    }

    init(_ request: AuthSignInWithOTPRequest,
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

        do {
            let result = try await doSignIn()
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

    private func doSignIn() async throws -> AuthSignInResult {
        let stateSequences = await authStateMachine.listen()
        log.verbose("Sending signIn event")
        await sendSignInEvent()
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
                // [HS] TODO: Update next steps when new StateMachine is updated for Passwordless
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



    private func sendSignInEvent() async {
        // [HS] TODO: Send Sign in Event
    }

    private func clientMetadata() -> [String: String] {

        if let options = request.options.pluginOptions as? AWSAuthSignUpAndSignInPasswordlessOptions,
            let clientMetadata = options.clientMetadata {
            return clientMetadata
        } else if let options = request.options.pluginOptions as? AWSAuthSignInPasswordlessOptions,
                  let clientMetadata = options.clientMetadata {
            return clientMetadata
        }
        return [:]
    }

    // MARK: Sign In Cancellation

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
}
