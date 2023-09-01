//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthConfirmSignInTask: AuthConfirmSignInTask, DefaultLogger {

    private let request: AuthConfirmSignInRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInAPI
    }

    init(_ request: AuthConfirmSignInRequest,
         stateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = stateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
    }

    func execute() async throws -> AuthSignInResult {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        //Check if we have a user pool configuration
        guard authConfiguration.getUserPoolConfiguration() != nil else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

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

        if case .resolvingChallenge(let challengeState, let challengeType, _) = signInState {

            // Validate if request valid MFA selection
            if case .selectMFAType = challengeType {
                try validateRequestForMFASelection()
            }

            switch challengeState {
            case .waitingForAnswer, .error:
                log.verbose("Sending confirm signIn event: \(challengeState)")
                await sendConfirmSignInEvent()
            default:
                throw invalidStateError
            }
        } else if case .resolvingTOTPSetup(let resolvingSetupTokenState, _) = signInState {
            switch resolvingSetupTokenState {
            case .waitingForAnswer, .error:
                log.verbose("Sending confirm signIn event: \(resolvingSetupTokenState)")
                await sendConfirmTOTPSetupEvent()
            default:
                throw invalidStateError
            }
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

    func validateRequestForMFASelection() throws {
        let challengeResponse = request.challengeResponse

        guard let _ = MFAType(rawValue: challengeResponse) else {
            throw AuthError.validation(
                AuthPluginErrorConstants.confirmSignInMFASelectionResponseError.field,
                AuthPluginErrorConstants.confirmSignInMFASelectionResponseError.errorDescription,
                AuthPluginErrorConstants.confirmSignInMFASelectionResponseError.recoverySuggestion)
        }
    }

    func sendConfirmSignInEvent() async {
        let event = SignInChallengeEvent(
            eventType: .verifyChallengeAnswer(createConfirmSignInEventData()))
        await authStateMachine.send(event)
    }

    func sendConfirmTOTPSetupEvent() async {
        let event = SetUpTOTPEvent(
            eventType: .verifyChallengeAnswer(createConfirmSignInEventData()))
        await authStateMachine.send(event)
    }

    private func createConfirmSignInEventData() -> ConfirmSignInEventData {
        let pluginOptions = (request.options.pluginOptions as? AWSAuthConfirmSignInOptions)

        // Convert the attributes to [String: String]
        let attributePrefix = AuthPluginConstants.cognitoIdentityUserUserAttributePrefix
        let attributes = pluginOptions?.userAttributes?.reduce(
            into: [String: String]()) {
                $0[attributePrefix + $1.key.rawValue] = $1.value
            } ?? [:]
        return ConfirmSignInEventData(
            answer: self.request.challengeResponse,
            attributes: attributes,
            metadata: pluginOptions?.metadata,
            friendlyDeviceName: pluginOptions?.friendlyDeviceName)
    }

    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
