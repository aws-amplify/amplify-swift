//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

struct PasswordlessConfirmSignInHelper: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let challengeResponse: String
    private let confirmSignInRequestMetadata: PasswordlessCustomAuthRequest
    private let pluginOptions: Any?

    init(authStateMachine: AuthStateMachine,
         challengeResponse: String,
         confirmSignInRequestMetadata: PasswordlessCustomAuthRequest,
         pluginOptions: Any?) {

        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.challengeResponse = challengeResponse
        self.confirmSignInRequestMetadata = confirmSignInRequestMetadata
        self.pluginOptions = pluginOptions
    }

    func confirmSignIn() async throws -> AuthSignInResult {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

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
                return try await parseAndValidate(signInResult: result)
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

    private func sendConfirmSignInEvent() async {
        let event = SignInChallengeEvent(
            eventType: .verifyChallengeAnswer(createConfirmSignInEventData()))
        await authStateMachine.send(event)
    }

    private func createConfirmSignInEventData() -> ConfirmSignInEventData {
        var passwordlessMetadata = confirmSignInRequestMetadata.toDictionary()
        if let customerMetadata = (pluginOptions as? AWSAuthConfirmSignInPasswordlessOptions)?.clientMetadata {
            passwordlessMetadata.merge(customerMetadata, uniquingKeysWith: { passwordlessMetadata, customerMetadata in
                // Ideally key collision won't happen, because passwordless has been namespaced
                // if for some reason collision still happens,
                // prioritizing passwordlessFlow keys for flow to continue without any issues.
                passwordlessMetadata

            })
        }
        return ConfirmSignInEventData(
            answer: challengeResponse,
            metadata: passwordlessMetadata)
    }

    private func parseAndValidate(signInResult: AuthSignInResult) async throws -> AuthSignInResult {

        guard case .confirmSignInWithCustomChallenge(let challengeParams) = signInResult.nextStep else {
            log.error("Did not receive custom auth challenge as a next Step instead received: \(signInResult)")
            throw AuthError.service(
                "Did not receive custom auth challenge as a next Step.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }
        guard  let nextStepString = challengeParams?["nextStep"] else {
            log.error("Did not receive a valid next step. Received Challenge Params:  \(challengeParams ?? [:])")
            throw AuthError.service(
                "Did not receive a valid next step for Confirm Passwordless flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        guard let nextStep = PasswordlessCustomAuthNextStep(rawValue: nextStepString) else {
            log.error("Invalid next step. Next Step\(nextStepString)")
            throw AuthError.service(
                "Did not receive a valid next step for Confirm Passwordless flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        switch nextStep {
        case .provideAuthParameters:
            log.error("This flow is not supported during confirm sign in")
            throw AuthError.service(
                "Did not receive a valid next step for Confirm Passwordless flow. \(nextStep)",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)

        case .provideChallengeResponse:
            return try PasswordlessHelper.getResultForChallengeParams(
                challengeParams, signInMethod: confirmSignInRequestMetadata.signInMethod)
        }
    }

}
