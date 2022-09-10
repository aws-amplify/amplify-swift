//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

class AWSAuthConfirmSignUpTask: AuthConfirmSignUpTask {

    private let request: AuthConfirmSignUpRequest
    private let authEnvironment: AuthEnvironment

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.confirmSignUpAPI
    }

    init(_ request: AuthConfirmSignUpRequest, authEnvironment: AuthEnvironment) {
        self.request = request
        self.authEnvironment = authEnvironment
    }

    func execute() async throws -> AuthSignUpResult {
        try request.hasError()
        let userPoolEnvironment = authEnvironment.userPoolEnvironment
        do {

            let client = try userPoolEnvironment.cognitoUserPoolFactory()
            let input = ConfirmSignUpInput(username: request.username,
                                           confirmationCode: request.code,
                                           environment: userPoolEnvironment)
            _ = try await client.confirmSignUp(input: input)
            return AuthSignUpResult(.done)
        } catch let error as AuthError {
            throw error
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch let error {
            let error = AuthError.configuration(
                "Unable to create a Swift SDK user pool service",
                AuthPluginErrorConstants.configurationError,
                error)
            throw error
        }
    }
}
