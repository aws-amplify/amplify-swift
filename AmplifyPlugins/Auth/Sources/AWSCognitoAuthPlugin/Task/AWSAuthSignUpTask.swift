//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

class AWSAuthSignUpTask: AuthSignUpTask, DefaultLogger {

    private let request: AuthSignUpRequest

    private let authEnvironment: AuthEnvironment

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Auth.signUpAPI
    }

    init(_ request: AuthSignUpRequest, authEnvironment: AuthEnvironment) {
        self.request = request
        self.authEnvironment = authEnvironment
    }

    func execute() async throws -> AuthSignUpResult {
        log.verbose("Starting execution")
        let userPoolEnvironment = authEnvironment.userPoolEnvironment
        try request.hasError()

        let pluginOptions = request.options.pluginOptions as? AWSAuthSignUpOptions
        let metaData = pluginOptions?.metadata
        let validationData = pluginOptions?.validationData
        do {
            let client = try userPoolEnvironment.cognitoUserPoolFactory()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: request.username,
                credentialStoreClient: authEnvironment.credentialsClient)
            let attributes = request.options.userAttributes?.reduce(
                into: [String: String]()) {
                    $0[$1.key.rawValue] = $1.value
                } ?? [:]
            let input = SignUpInput(username: request.username,
                                    password: request.password!,
                                    clientMetadata: metaData,
                                    validationData: validationData,
                                    attributes: attributes,
                                    asfDeviceId: asfDeviceId,
                                    environment: userPoolEnvironment)

            let response = try await client.signUp(input: input)
            log.verbose("Received result")
            return response.authResponse
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            throw AuthError.configuration(
                "Unable to create a Swift SDK user pool service",
                AuthPluginErrorConstants.configurationError,
                error
            )
        }
    }

    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))
    }
    
    public var log: Logger {
        Self.log
    }
}
