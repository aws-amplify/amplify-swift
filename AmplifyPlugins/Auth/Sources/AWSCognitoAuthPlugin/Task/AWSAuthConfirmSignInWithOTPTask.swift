//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthConfirmSignInWithOTPTask: AuthConfirmSignInWithOTPTask, DefaultLogger {

    private let request: AuthConfirmSignInWithOTPRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration
    private let confirmSignInRequestMetadata: PasswordlessCustomAuthRequest

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInWithOTPAPI
    }

    init(_ request: AuthConfirmSignInWithOTPRequest,
         stateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = stateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
        self.confirmSignInRequestMetadata = .init(signInMethod: .otp, action: .confirm)
    }

    func execute() async throws -> AuthSignInResult {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        if let validationError = request.hasError() {
            throw validationError
        }
        let invalidStateError = AuthError.invalidState(
            "User is not attempting signIn operation",
            AuthPluginErrorConstants.invalidStateError, nil)

        guard case .configured(let authNState, _) = await authStateMachine.currentState,
              case .signingIn(let signInState) = authNState else {
            throw invalidStateError
        }

        guard case .resolvingChallenge(let challengeState, _, _) = signInState else {
            throw invalidStateError
        }

        switch challengeState {
        case .waitingForAnswer, .error:
            log.verbose("Sending confirm signIn event: \(challengeState)")
            await sendConfirmSignInEvent()
        default:
            throw invalidStateError
        }

        let stateSequences = await authStateMachine.listen()
        log.verbose("Waiting for response")
        for await state in stateSequences {
            guard case .configured(let authNState, let authZState) = state else {
                continue
            }
            switch authNState {
            case .signedIn:
                if case .sessionEstablished = authZState {
                    return AuthSignInResult(nextStep: .done)
                } else {
                    log.verbose("Signed In, waiting for authorization to complete")
                }
            case .error(let error):
                throw AuthError.unknown("Sign in reached an error state", error)

            case .signingIn(let signInState):
                guard let result = try UserPoolSignInHelper.checkNextStep(signInState) else {
                    continue
                }
                return result
            case .notConfigured:
                throw AuthError.configuration(
                    "UserPool configuration is missing",
                    AuthPluginErrorConstants.configurationError)
            default:
                throw invalidStateError
            }
        }
        throw invalidStateError
    }

    func sendConfirmSignInEvent() async {
        let event = SignInChallengeEvent(
            eventType: .verifyChallengeAnswer(createConfirmSignInEventData()))
        await authStateMachine.send(event)
    }

    private func createConfirmSignInEventData() -> ConfirmSignInEventData {
        // TODO:
        // Discuss if we should have dedicated options for ConfirmSignWith OTP
        // Because `AWSAuthConfirmSignInOptions` has `friendlyDeviceName` and `userAttributes`
        // that is not supported by this task. Customers might get confused that these are supported fields.
        var passwordlessMetadata = confirmSignInRequestMetadata.toDictionary()
        if let customerMetadata = (request.options.pluginOptions as? AWSAuthConfirmSignInOptions)?.metadata {
            passwordlessMetadata.merge(customerMetadata, uniquingKeysWith: { passwordlessMetadata, customerMetadata in
                // TODO: Discuss with team to namespace passwordless metadata
                // Giving precedence to passwordless metadata.
                passwordlessMetadata

            })
        }
        return ConfirmSignInEventData(
            answer: self.request.challengeResponse,
            metadata: passwordlessMetadata)
    }
}
