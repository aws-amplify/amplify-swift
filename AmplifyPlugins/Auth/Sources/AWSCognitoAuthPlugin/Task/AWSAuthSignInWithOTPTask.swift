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

    let passwordlessSignInHelper: PasswordlessSignInHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithOTPAPI
    }

    init(_ request: AuthSignInWithOTPRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration,
         authEnvironment: AuthEnvironment) {
        passwordlessSignInHelper = PasswordlessSignInHelper(
            authStateMachine: authStateMachine,
            configuration: configuration,
            authEnvironment: authEnvironment,
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
    }

    func execute() async throws -> AuthSignInResult {
        return try await passwordlessSignInHelper.signIn()
    }
}
