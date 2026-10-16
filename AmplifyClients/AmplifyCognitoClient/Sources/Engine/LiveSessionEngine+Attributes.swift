//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

/// User attributes and password change, ported from the plugin's `AWSAuthFetchUserAttributeTask`,
/// `AWSAuthUpdateUserAttributeTask` / `AWSAuthUpdateUserAttributesTask` (through
/// `UpdateAttributesOperationHelper`), `AWSAuthSendUserAttributeVerificationCodeTask` (and the deprecated
/// `AWSAuthAttributeResendConfirmationCodeTask`, which sends the same request), `AWSAuthConfirmUserAttributeTask`
/// and `AWSAuthChangePasswordTask`.
///
/// Each calls Cognito directly with the payload's access token, as the plugin's tasks do, and never refreshes:
/// the core has already handed over a fresh payload (route 2). None of them reads or writes the session's
/// credentials, and none touches the actor's state, so a pending sign-in is never disturbed. As the plugin, the
/// client metadata is sent as given, `[:]` for none (`?? [:]` in every task), not omitted.
extension LiveSessionEngine {

    /// The user's attributes (`AWSAuthFetchUserAttributeTask.getUserAttributes`): every attribute with a name
    /// and a value, keyed by the client's key for its Cognito name.
    ///
    /// - Throws: Cognito's answer, mapped; `unknown` if Cognito answers without attributes (with the plugin's
    ///   message).
    nonisolated func fetchUserAttributes(_ payload: Data) async throws -> [AuthClientUserAttribute] {
        let accessToken = try attributeOperationAccessToken(in: payload)
        let userPool = try attributeOperationUserPool()
        let output = try await Self.mappingAttributeOperationErrors {
            try await userPool.getUser(input: GetUserInput(accessToken: accessToken))
        }
        guard let attributes = output.userAttributes else {
            // The plugin's `AuthError.unknown(…, nil)`, so its wording ("Unexpected error occurred with
            // message: …") and suggestion, and its message, although no delivery details are involved.
            throw AuthClientError(engine: .unknown("Unable to get Auth code delivery details"))
        }
        return attributes.compactMap { attribute in
            guard let name = attribute.name, let value = attribute.value else {
                return nil
            }
            return AuthClientUserAttribute(AuthClientUserAttributeKey(cognitoName: name), value: value)
        }
    }

    /// Updates the attributes in one request (`UpdateAttributesOperationHelper.update`).
    ///
    /// - Returns: For each attribute Cognito sent a code for, not updated yet, with
    ///   `.confirmAttributeWithCode(details, nil)`; for every other attribute asked for, updated, `.done`.
    /// - Throws: Cognito's answer, mapped.
    nonisolated func updateUserAttributes(
        _ payload: Data,
        attributes: [AuthClientUserAttribute],
        clientMetadata: [String: String]
    ) async throws -> [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult] {
        let accessToken = try attributeOperationAccessToken(in: payload)
        let userPool = try attributeOperationUserPool()
        let output = try await Self.mappingAttributeOperationErrors {
            try await userPool.updateUserAttributes(input: UpdateUserAttributesInput(
                accessToken: accessToken,
                clientMetadata: clientMetadata,
                userAttributes: attributes.map {
                    CognitoIdentityProviderClientTypes.AttributeType(name: $0.key.cognitoName, value: $0.value)
                }
            ))
        }
        var results: [AuthClientUserAttributeKey: AuthClientUpdateAttributeResult] = [:]
        for item in output.codeDeliveryDetailsList ?? [] {
            guard let attribute = item.attributeName else {
                continue
            }
            results[AuthClientUserAttributeKey(cognitoName: attribute)] = AuthClientUpdateAttributeResult(
                isUpdated: false,
                nextStep: .confirmAttributeWithCode(AuthClientCodeDeliveryDetails(item.toEngineCodeDeliveryDetails()), nil)
            )
        }
        for attribute in attributes where results[attribute.key] == nil {
            results[attribute.key] = AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)
        }
        return results
    }

    /// Sends a code to verify an attribute (`AWSAuthSendUserAttributeVerificationCodeTask`).
    ///
    /// - Throws: Cognito's answer, mapped; `unknown` if Cognito answers without delivery details.
    nonisolated func sendVerificationCode(
        _ payload: Data,
        attributeKey: AuthClientUserAttributeKey,
        clientMetadata: [String: String]
    ) async throws -> AuthClientCodeDeliveryDetails {
        let accessToken = try attributeOperationAccessToken(in: payload)
        let userPool = try attributeOperationUserPool()
        let output = try await Self.mappingAttributeOperationErrors {
            try await userPool.getUserAttributeVerificationCode(input: GetUserAttributeVerificationCodeInput(
                accessToken: accessToken,
                attributeName: attributeKey.cognitoName,
                clientMetadata: clientMetadata
            ))
        }
        guard let details = output.codeDeliveryDetails?.toEngineCodeDeliveryDetails() else {
            // The plugin's `AuthError.unknown(…, nil)`, so its wording ("Unexpected error occurred with
            // message: …") and suggestion.
            throw AuthClientError(engine: .unknown("Unable to get Auth code delivery details"))
        }
        return AuthClientCodeDeliveryDetails(details)
    }

    /// Confirms an attribute with its code (`AWSAuthConfirmUserAttributeTask.confirmUserAttribute`).
    ///
    /// - Throws: Cognito's answer, mapped (`codeMismatch`, `codeExpired`, …).
    nonisolated func confirmUserAttribute(_ payload: Data, attributeKey: AuthClientUserAttributeKey, confirmationCode: String) async throws {
        let accessToken = try attributeOperationAccessToken(in: payload)
        let userPool = try attributeOperationUserPool()
        _ = try await Self.mappingAttributeOperationErrors {
            try await userPool.verifyUserAttribute(input: VerifyUserAttributeInput(
                accessToken: accessToken,
                attributeName: attributeKey.cognitoName,
                code: confirmationCode
            ))
        }
    }

    /// Changes the password (`AWSAuthChangePasswordTask.changePassword`).
    ///
    /// - Throws: Cognito's answer, mapped (`notAuthorized` for a wrong old password, `invalidPassword`, …).
    nonisolated func changePassword(_ payload: Data, oldPassword: String, newPassword: String) async throws {
        let accessToken = try attributeOperationAccessToken(in: payload)
        let userPool = try attributeOperationUserPool()
        _ = try await Self.mappingAttributeOperationErrors {
            try await userPool.changePassword(input: ChangePasswordInput(
                accessToken: accessToken,
                previousPassword: oldPassword,
                proposedPassword: newPassword
            ))
        }
    }

    // MARK: Support

    /// The payload's access token, as it is. The core refuses a session without one before the engine is
    /// called (`notSignedIn`), so the throw only guards the seam's contract.
    nonisolated func attributeOperationAccessToken(in payload: Data) throws -> String {
        try requireUserPool()
        guard let accessToken = try accessToken(in: payload) else {
            throw SessionEngineError.notSignedIn
        }
        return accessToken
    }

    /// The Cognito user pool the operations call: the session's SDK client, or a test's double.
    nonisolated func attributeOperationUserPool() throws -> any CognitoUserPoolBehavior {
        try EngineResources.required(resources.services.userPool, "user pool")
    }

    /// Runs one Cognito call, mapping its failure as the plugin does (`AuthError(converting:)`). Anything
    /// else, such as a cancellation, passes through to the core's mapping.
    static func mappingAttributeOperationErrors<Output>(_ call: () async throws -> Output) async throws -> Output {
        do {
            return try await call()
        } catch let error as EngineAuthErrorConvertible {
            throw AuthClientError(engine: error.engineError)
        }
    }
}
