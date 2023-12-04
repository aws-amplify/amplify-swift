//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct PasswordlessSignUpHelper: DefaultLogger {

    private let authStateMachine: AuthStateMachine
    private let taskHelper: AWSAuthTaskHelper
    private let authEnvironment: AuthEnvironment
    private let authConfiguration: AuthConfiguration?
    private let username: String
    private let signInRequestMetadata: PasswordlessCustomAuthRequest
    private let pluginOptions: Any?

    init(authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration?,
         authEnvironment: AuthEnvironment,
         username: String,
         signInRequestMetadata: PasswordlessCustomAuthRequest,
         pluginOptions: Any?) {
        self.authStateMachine = authStateMachine
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.authConfiguration = configuration
        self.authEnvironment = authEnvironment
        self.username = username
        self.signInRequestMetadata = signInRequestMetadata
        self.pluginOptions = pluginOptions
    }

    func signUp() async throws {
        log.verbose("Starting execution")
        await taskHelper.didStateMachineConfigured()

        do {
            // Make sure current state is a valid state to begin sign up
            try await validateCurrentState()

            // Start sign up
            
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

            guard let authPasswordlessClient = try authEnvironment.authPasswordlessEnvironment?.authPasswordlessFactory() else {
                let message = AuthPluginErrorConstants.configurationError
                let authError = AuthError.configuration(
                    "URL Session client is not set up",
                    message)
                throw authError
            }
            
            guard let endpoint = userPoolConfiguration.passwordlessSignUpEndpoint else {
                let message = AuthPluginErrorConstants.configurationError
                let authError = AuthError.configuration(
                    "API Gateway endpoint not found in configuration",
                    message)
                throw authError
            }
            
            guard let endpointURL = URL(string: endpoint) else {
                let message = AuthPluginErrorConstants.configurationError
                let authError = AuthError.configuration(
                    "API Gateway URL is not valid",
                    message)
                throw authError
            }
            
            guard let deliveryMedium = signInRequestMetadata.deliveryMedium else {
                let message = AuthPluginErrorConstants.configurationError
                let authError = AuthError.configuration(
                    "Delivery medium is not specified",
                    message)
                throw authError
            }
            
            var userAttributes : [String:String] = [:]
            if let pluginOptions = pluginOptions as? AWSAuthSignUpAndSignInPasswordlessOptions,
               let attributes = pluginOptions.userAttributes {
                userAttributes = attributes
            }
            
            let payload = PreInitiateAuthSignUpPayload(username: username,
                                                       deliveryMedium: deliveryMedium.rawValue,
                                                       userAttributes: userAttributes,
                                                       userPoolId: userPoolConfiguration.poolId,
                                                       region: userPoolConfiguration.region)
            return try await authPasswordlessClient.preInitiateAuthSignUp(endpoint: endpointURL,
                                                                          payload: payload)
        } catch {

            log.error(error: error)
            
            // If Passwordless SignUp, send sign in cancellation event
            await sendCancelSignInEvent()

            // Wait for sign in cancellation to complete
            await waitForSignInCancel()

            // throw error that came during sign up
            throw error
        }
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
