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

    private let confirmSignInHelper: PasswordlessConfirmSignInHelper
    private let request: AuthConfirmSignInWithOTPRequest

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignInWithOTPAPI
    }

    init(_ request: AuthConfirmSignInWithOTPRequest,
         stateMachine: AuthStateMachine,
         configuration: AuthConfiguration) {
        self.request = request
        self.confirmSignInHelper = PasswordlessConfirmSignInHelper(
            authStateMachine: stateMachine,
            challengeResponse: request.challengeResponse,
            confirmSignInRequestMetadata: .init(signInMethod: .otp, action: .confirm),
            pluginOptions: request.options.pluginOptions)
    }

    func execute() async throws -> AuthSignInResult {
        if let validationError = request.hasError() {
            throw validationError
        }
        return try await confirmSignInHelper.confirmSignIn()
    }
}
