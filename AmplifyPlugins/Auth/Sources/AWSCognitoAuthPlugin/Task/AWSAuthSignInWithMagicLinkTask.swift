//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthSignInWithMagicLinkTask: AuthSignInWithMagicLinkTask, DefaultLogger {

    let passwordlessSignInHelper: PasswordlessSignInHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signInWithMagicLinkAPI
    }

    init(_ request: AuthSignInWithMagicLinkRequest,
         authStateMachine: AuthStateMachine,
         configuration: AuthConfiguration,
         authEnvironment: AuthEnvironment) {
        passwordlessSignInHelper = PasswordlessSignInHelper(
            authStateMachine: authStateMachine,
            configuration: configuration,
            authEnvironment: authEnvironment,
            username: request.username,
            // NOTE: answer is not applicable in this scenario
            // because this event is only responsible for initializing the passwordless OTP workflow
            challengeAnswer: "",
            signInRequestMetadata: .init(
                signInMethod: .magicLink, 
                action: .request,
                deliveryMedium: .email,
                redirectURL: request.redirectURL),
            passwordlessFlow: request.flow,
            pluginOptions: request.options.pluginOptions)
    }

    func execute() async throws -> AuthSignInResult {
        return try await passwordlessSignInHelper.signIn()
    }
}
