//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInWithMagicLinkTask: AuthSignInWithMagicLinkTask, DefaultLogger {

    private let request: AuthSignInWithMagicLinkRequest
    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration
    private let signInMetadataRequestMetadata: PasswordlessCustomAuthRequest

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithMagicLinkAPI
    }

    // TODO: Add authEnvironment parameter here to access URLSessionClient
    init(_ request: AuthSignInWithMagicLinkRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
        self.signInMetadataRequestMetadata = .init(
            signInMethod: .magicLink, action: .request, deliveryMedium: .email, redirectURL: request.redirectURL)
    }

    func execute() async throws -> AuthSignInResult {

        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        // Check if we have a user pool configuration
        // User pool configuration is used retrieve API Gateway information,
        // so that sign up flow can take place
        guard let userPoolConfiguration = authConfiguration.getUserPoolConfiguration() else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthError.configuration(
                "Could not find user pool configuration",
                message)
            throw authError
        }

        // Make sure current state is a valid state to initialize sign in
        try await validateCurrentState()

        do {
            // Start magic link sign in
            return try await startMagicLinkSignIn()
        } catch {

            log.error(error: error)
            // If Magic Link Sign in failed, send sign in cancellation event
            await sendCancelSignInEvent()

            // Wait for sign in cancellation to complete
            await waitForSignInCancel()

            // throw error that came during sign in
            throw error
        }
    }

    

    private func startMagicLinkSignIn() async throws -> AuthSignInResult {
        if request.flow == .signUpAndSignIn {
            log.verbose("Starting Magic Link Passwordless Sign Up flow")
            // TODO: Access the URLSession Client and auth configuration and make HTTP
            //       POST to API Gateway endpoint
        }

        log.verbose("Starting Magic Link Passwordless Sign In flow")
        let result = try await doSignIn()

        log.verbose("Received result")
        return result
    }

    private func doSignIn() async throws -> AuthSignInResult {

        log.verbose("Sending initiate Sign In event")
        await sendInitiateSignInEvent()

        log.verbose("Start listening to state machine changes")
        return try await listenToStateChanges()
    }

    func listenToStateChanges() async throws -> AuthSignInResult {
        let stateSequences = await authStateMachine.listen()
        for await state in stateSequences {
            guard case .configured(let authNState, let authZState) = state else {
                continue
            }
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
                guard let nextStepResult = try UserPoolSignInHelper.checkNextStep(signInState) else {
                    continue
                }
                guard let signInResult = try await parseAndValidate(signInResult: nextStepResult) else {
                    continue
                }
                return signInResult
            default:
                continue
            }
        }
        throw AuthError.unknown("Sign in reached an error state")
    }

    func parseAndValidate(signInResult: AuthSignInResult) async throws -> AuthSignInResult? {

        guard case .confirmSignInWithCustomChallenge(let challengeParams) = signInResult.nextStep else {
            log.error("Did not receive custom auth challenge as a next Step instead received: \(signInResult)")
            throw AuthError.service(
                "Did not receive custom auth challenge as a next Step.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }
        guard  let nextStepString = challengeParams?["nextStep"] else {
            log.error("Did not receive a valid next step. Received Challenge Params:  \(challengeParams ?? [:])")
            throw AuthError.service(
                "Did not receive a valid next step for Passwordless Magic Link flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        guard let nextStep = PasswordlessCustomAuthNextStep(rawValue: nextStepString) else {
            log.error("Invalid next step. Next Step\(nextStepString)")
            throw AuthError.service(
                "Did not receive a valid next step for Passwordless Magic Link flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        switch nextStep {
        case .provideAuthParameters:
            log.verbose("Sending Response for InitAuth challenge")
            // Library handles creating auth parameters
            await sendEventForProvidingAuthParameters()
            return nil

        case .provideChallengeResponse:
            // Ask the customer for magiclink code
            return .init(nextStep: .confirmSignInWithMagicLink(
                getCodeDeliveryDetails(parameters: challengeParams ?? [:]), nil))
        }
    }

    // MARK: Events

    private func sendInitiateSignInEvent() async {
        let signInData = SignInEventData(
            username: request.username,
            clientMetadata: customerClientMetadata(),
            signInMethod: .apiBased(.customWithoutSRP)
        )
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        await authStateMachine.send(event)
    }

    private func sendEventForProvidingAuthParameters() async {
        var passwordlessFlowMetadata = signInMetadataRequestMetadata.toDictionary()
        passwordlessFlowMetadata.merge(customerClientMetadata()) { passwordlessFlowMetadata, customerClientMetadata in
            // Ideally key collision won't happen, because passwordless has been namespaced
            // if for some reason collision still happens,
            // prioritizing passwordlessFlow keys for flow to continue without any issues.
            passwordlessFlowMetadata
        }
        let confirmSignInEventData = ConfirmSignInEventData(
            // NOTE: answer is not applicable in this scenario
            // because this event is only responsible for initializing the passwordless magiclink workflow
            answer: "",
            metadata: passwordlessFlowMetadata)
        let event = SignInChallengeEvent(
            eventType: .verifyChallengeAnswer(confirmSignInEventData))
        await authStateMachine.send(event)
    }

    // MARK: State Validations

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

    // MARK: Private helpers

    private func customerClientMetadata() -> [String: String] {

        if let options = request.options.pluginOptions as? AWSAuthSignUpAndSignInPasswordlessOptions,
            let clientMetadata = options.clientMetadata {
            return clientMetadata
        } else if let options = request.options.pluginOptions as? AWSAuthSignInPasswordlessOptions,
                  let clientMetadata = options.clientMetadata {
            return clientMetadata
        }
        return [:]
    }

    private func getCodeDeliveryDetails(parameters: [String: String]) -> AuthCodeDeliveryDetails {

        var deliveryDestination = DeliveryDestination.unknown(nil)
        var attribute: AuthUserAttributeKey? = nil

        // Retrieve Delivery medium and destination
        let medium = parameters["deliveryMedium"]
        let destination = parameters["destination"]
        if medium == "SMS" {
            deliveryDestination = .sms(destination)
        } else if medium == "EMAIL" {
            deliveryDestination = .email(destination)
        }

        // Retrieve attribute name
        if let attributeName = parameters["attributeName"] {
            attribute = AuthUserAttributeKey(rawValue: attributeName)
        }

        return AuthCodeDeliveryDetails(
            destination: deliveryDestination,
            attributeKey: attribute)
    }

    // MARK: Sign In Cancellation

    private func sendCancelSignInEvent() async {
        let event = AuthenticationEvent(eventType: .cancelSignIn)
        await authStateMachine.send(event)
    }

    private func waitForSignInCancel() async {
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
