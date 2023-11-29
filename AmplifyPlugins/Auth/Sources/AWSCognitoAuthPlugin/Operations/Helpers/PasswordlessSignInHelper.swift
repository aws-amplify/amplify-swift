//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct PasswordlessSignInHelper: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authConfiguration: AuthConfiguration?
    private let username: String
    private let challengeAnswer: String
    private let signInRequestMetadata: PasswordlessCustomAuthRequest
    private let passwordlessFlow: AuthPasswordlessFlow
    private let pluginOptions: Any?

    // TODO: Add authEnvironment parameter here to access URLSessionClient
    init(authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration?,
         username: String,
         challengeAnswer: String,
         signInRequestMetadata: PasswordlessCustomAuthRequest,
         passwordlessFlow: AuthPasswordlessFlow,
         pluginOptions: Any?) {

        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
        self.username = username
        self.challengeAnswer = challengeAnswer
        self.signInRequestMetadata = signInRequestMetadata
        self.passwordlessFlow = passwordlessFlow
        self.pluginOptions = pluginOptions
    }

    func signIn() async throws -> AuthSignInResult {

        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        do {
            // Make sure current state is a valid state to initialize sign in
            try await validateCurrentState()
            
            if passwordlessFlow == .signUpAndSignIn {
                // Check if we have a user pool configuration
                // User pool configuration is used retrieve API Gateway information,
                // so that sign up flow can take place
                guard let userPoolConfiguration = authConfiguration?.getUserPoolConfiguration() else {
                    let message = AuthPluginErrorConstants.configurationError
                    let authError = AuthError.configuration(
                        "Could not find user pool configuration",
                        message)
                    throw authError
                }

                log.verbose("Starting Passwordless Sign Up flow")
                // [HS] TODO: Proceed to sign up flow first
            }

            // Start sign in
            return try await startPasswordlessSignIn()
        } catch {

            log.error(error: error)
            // If Passwordless Sign in failed, send sign in cancellation event
            await sendCancelSignInEvent()

            // Wait for sign in cancellation to complete
            await waitForSignInCancel()

            // throw error that came during sign in
            throw error
        }
    }



    private func startPasswordlessSignIn() async throws -> AuthSignInResult {

        log.verbose("Starting Passwordless Sign In flow")
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

    private func listenToStateChanges() async throws -> AuthSignInResult {
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

    private func parseAndValidate(signInResult: AuthSignInResult) async throws -> AuthSignInResult? {

        guard case .confirmSignInWithCustomChallenge(let challengeParams) = signInResult.nextStep else {
            log.error("Did not receive custom auth challenge as a next Step instead received: \(signInResult)")
            throw AuthError.service(
                "Did not receive custom auth challenge as a next Step.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }
        guard  let nextStepString = challengeParams?["nextStep"] else {
            log.error("Did not receive a valid next step. Received Challenge Params:  \(challengeParams ?? [:])")
            throw AuthError.service(
                "Did not receive a valid next step for Passwordless \(signInRequestMetadata.signInMethod) flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        guard let nextStep = PasswordlessCustomAuthNextStep(rawValue: nextStepString) else {
            log.error("Invalid next step. Next Step\(nextStepString)")
            throw AuthError.service(
                "Did not receive a valid next step for Passwordless \(signInRequestMetadata.signInMethod) flow.",
                AmplifyErrorMessages.shouldNotHappenReportBugToAWS(), nil)
        }

        switch nextStep {
        case .provideAuthParameters:
            log.verbose("Sending Response for InitAuth challenge")
            // Library handles creating auth parameters
            await sendEventForProvidingAuthParameters()
            return nil

        case .provideChallengeResponse:
            // Ask the customer for the next step
            switch signInRequestMetadata.signInMethod{
            case .otp:
                return .init(nextStep: .confirmSignInWithOTP(
                    getCodeDeliveryDetails(parameters: challengeParams ?? [:]), nil))
            case .magicLink:
                return .init(nextStep: .confirmSignInWithMagicLink(
                    getCodeDeliveryDetails(parameters: challengeParams ?? [:]), nil))
            }
        }
    }

    // MARK: Events

    private func sendInitiateSignInEvent() async {
        let signInData = SignInEventData(
            username: username,
            clientMetadata: customerClientMetadata(),
            signInMethod: .apiBased(.customWithoutSRP)
        )
        let event = AuthenticationEvent.init(eventType: .signInRequested(signInData))
        await authStateMachine.send(event)
    }

    private func sendEventForProvidingAuthParameters() async {
        var passwordlessFlowMetadata = signInRequestMetadata.toDictionary()
        passwordlessFlowMetadata.merge(customerClientMetadata()) { passwordlessFlowMetadata, customerClientMetadata in
            // Ideally key collision won't happen, because passwordless has been namespaced
            // if for some reason collision still happens,
            // prioritizing passwordlessFlow keys for flow to continue without any issues.
            passwordlessFlowMetadata
        }
        let confirmSignInEventData = ConfirmSignInEventData(
            answer: challengeAnswer,
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

        if let options = pluginOptions as? AWSAuthSignUpAndSignInPasswordlessOptions,
           let clientMetadata = options.clientMetadata {
            return clientMetadata
        } else if let options = pluginOptions as? AWSAuthSignInPasswordlessOptions,
                  let clientMetadata = options.clientMetadata {
            return clientMetadata
        } else if let options = pluginOptions as? AWSAuthConfirmSignInWithMagicLinkOptions,
                  let clientMetadata = options.metadata {
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
