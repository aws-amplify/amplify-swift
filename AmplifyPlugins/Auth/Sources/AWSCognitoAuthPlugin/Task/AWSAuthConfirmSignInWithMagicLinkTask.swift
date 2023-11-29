//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Amplify
import AWSPluginsCore

class AWSAuthConfirmSignInWithMagicLinkTask: AuthConfirmSignInWithMagicLinkTask, DefaultLogger {

    let passwordlessSignInHelper: PasswordlessSignInHelper

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInWithMagicLinkAPI
    }

    init(_ request: AuthConfirmSignInWithMagicLinkRequest,
         stateMachine: AuthStateMachine,
         configuration: AuthConfiguration) throws {

        let username = try MagicLinkTokenParser.extractUserName(from: request.challengeResponse)
        passwordlessSignInHelper = PasswordlessSignInHelper(
            authStateMachine: stateMachine,
            configuration: nil,
            username: username,
            challengeAnswer: request.challengeResponse,
            signInRequestMetadata: .init(
                signInMethod: .magicLink,
                action: .confirm),
            passwordlessFlow: .signIn,
            pluginOptions: request.options.pluginOptions)
    }

    func execute() async throws -> AuthSignInResult {
        return try await passwordlessSignInHelper.signIn()
    }

}
