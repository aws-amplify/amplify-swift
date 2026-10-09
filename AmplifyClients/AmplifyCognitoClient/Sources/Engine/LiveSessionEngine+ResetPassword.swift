//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// Password reset, ported from the plugin's `AWSAuthResetPasswordTask` and
/// `AWSAuthConfirmResetPasswordTask`.
///
/// Both call Cognito directly, as the plugin's tasks do, with the plugin's advanced-security context (the ASF
/// device ID from the per-user device records), analytics metadata and secret hash, over the environment of a
/// configured operation. Neither reads or writes the session's credentials, nor touches the actor's state, so
/// a pending sign-in is never disturbed. As the plugin, the client metadata is sent as given, `[:]` for none
/// (`?? [:]` in both tasks), not omitted.
extension LiveSessionEngine {

    /// Starts a password reset (`AWSAuthResetPasswordTask.resetPassword`).
    ///
    /// - Returns: `.confirmResetPasswordWithCode(details, [:])`, not reset yet, as the plugin.
    /// - Throws: Cognito's answer, mapped; `unknown` if Cognito answers without delivery details.
    nonisolated func resetPassword(username: String, clientMetadata: [String: String]) async throws -> AuthClientResetPasswordResult {
        let output = try await withResetPasswordContext(for: username) { context in
            try await context.userPool.forgotPassword(input: ForgotPasswordInput(
                analyticsMetadata: context.analyticsMetadata,
                clientId: context.clientId,
                clientMetadata: clientMetadata,
                secretHash: context.secretHash,
                userContextData: context.userContextData,
                username: username
            ))
        }
        guard let details = output.codeDeliveryDetails?.toEngineCodeDeliveryDetails() else {
            // The plugin's `AuthError.unknown(…, nil)`, so its wording ("Unexpected error occurred with
            // message: …") and suggestion.
            throw AuthClientError(engine: .unknown("Unable to get Auth code delivery details"))
        }
        return AuthClientResetPasswordResult(
            isPasswordReset: false,
            nextStep: .confirmResetPasswordWithCode(AuthClientCodeDeliveryDetails(details), [:])
        )
    }

    /// Completes a password reset (`AWSAuthConfirmResetPasswordTask.confirmResetPassword`).
    ///
    /// - Throws: Cognito's answer, mapped (`codeMismatch`, `codeExpired`, `invalidPassword`, …).
    nonisolated func confirmResetPassword(_ request: EngineConfirmResetPasswordRequest) async throws {
        _ = try await withResetPasswordContext(for: request.username) { context in
            try await context.userPool.confirmForgotPassword(input: ConfirmForgotPasswordInput(
                analyticsMetadata: context.analyticsMetadata,
                clientId: context.clientId,
                clientMetadata: request.clientMetadata,
                confirmationCode: request.confirmationCode,
                password: request.newPassword,
                secretHash: context.secretHash,
                userContextData: context.userContextData,
                username: request.username
            ))
        }
    }

    // MARK: Support

    /// What both reset requests carry besides their own fields, built as the plugin's tasks build it.
    struct ResetPasswordRequestContext: Sendable {
        let userPool: any CognitoUserPoolBehavior
        let clientId: String
        let secretHash: String?
        let userContextData: CognitoIdentityProviderClientTypes.UserContextDataType
        let analyticsMetadata: CognitoIdentityProviderClientTypes.AnalyticsMetadataType?
    }

    /// Builds the request context for `username` and runs `call` with it, mapping a Cognito or device-record
    /// failure as the plugin does (`AuthError(converting:)`). Anything else, such as a cancellation, passes
    /// through to the core's mapping.
    nonisolated func withResetPasswordContext<Output: Sendable>(
        for username: String,
        _ call: @Sendable (ResetPasswordRequestContext) async throws -> Output
    ) async throws -> Output {
        try requireUserPool()
        let resources = resources
        guard let userPoolConfiguration = resources.authConfiguration.getUserPoolConfiguration() else {
            // `requireUserPool` has already refused this.
            throw AuthClientError.configuration(
                "UserPool configuration is missing",
                "Add a user pool to AuthClientConfiguration."
            )
        }
        // The operation's machines give the request the device records the plugin's environment reads.
        let operation = try resources.makeOperation(seed: nil)
        try await operation.configure(resources.authConfiguration)
        let environment = resources
            .makeEnvironmentFactory(credentialStore: operation.credentialStore)
            .makeAuthEnvironment(credentialsClient: CredentialStoreOperationClient(
                credentialStoreStateMachine: operation.credentialMachine
            ))
        do {
            let userPoolEnvironment = environment.userPoolEnvironment
            let userPool = try userPoolEnvironment.cognitoUserPoolFactory()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: environment.credentialsClient
            )
            let encodedData = await CognitoUserPoolASF.encodedContext(
                username: username,
                asfDeviceId: asfDeviceId,
                asfClient: userPoolEnvironment.cognitoUserPoolASFFactory(),
                userPoolConfiguration: userPoolConfiguration
            )
            let analyticsMetadata = await userPoolEnvironment
                .cognitoUserPoolAnalyticsHandlerFactory()
                .analyticsMetadata()
            let context = ResetPasswordRequestContext(
                userPool: userPool,
                clientId: userPoolConfiguration.clientId,
                secretHash: ClientSecretHelper.calculateSecretHash(
                    username: username,
                    userPoolConfiguration: userPoolConfiguration
                ),
                userContextData: CognitoIdentityProviderClientTypes.UserContextDataType(encodedData: encodedData),
                analyticsMetadata: analyticsMetadata
            )
            return try await call(context)
        } catch let error as EngineAuthErrorConvertible {
            throw AuthClientError(engine: error.engineError)
        }
    }
}
