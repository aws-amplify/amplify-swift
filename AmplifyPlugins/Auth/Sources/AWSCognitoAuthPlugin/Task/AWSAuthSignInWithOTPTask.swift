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

    let passwordlessFlow: AuthPasswordlessFlow
    let passwordlessSignInHelper: PasswordlessSignInHelper
    let passwordlessSignUpHelper: PasswordlessSignUpHelper
    
    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithOTPAPI
    }

    init(_ request: AuthSignInWithOTPRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration,
         authEnvironment: AuthEnvironment) {
        passwordlessFlow = request.flow
        
        // sign in helper
        passwordlessSignInHelper = PasswordlessSignInHelper(
            authStateMachine: authStateMachine,
            username: request.username,
            // NOTE: answer is not applicable in this scenario
            // because this event is only responsible for initializing the passwordless workflow
            challengeAnswer: "",
            signInRequestMetadata: .init(
                signInMethod: .otp,
                action: .request,
                deliveryMedium: request.destination),
            passwordlessFlow: request.flow,
            pluginOptions: request.options.pluginOptions)
        
        // sign up helper
        passwordlessSignUpHelper = PasswordlessSignUpHelper(
            authStateMachine: authStateMachine,
            configuration: configuration,
            authEnvironment: authEnvironment,
            username: request.username,
            signInRequestMetadata: .init(
                signInMethod: .otp,
                action: .request,
                deliveryMedium: request.destination),
            pluginOptions: request.options.pluginOptions)
    }

    func execute() async throws -> AuthSignInResult {
        if passwordlessFlow == .signUpAndSignIn {
            log.verbose("Starting Passwordless Sign Up flow")
            try await passwordlessSignUpHelper.signUp()
            log.verbose("Passwordless Sign Up flow success")
        }
        
        return try await passwordlessSignInHelper.signIn()
    }
}
