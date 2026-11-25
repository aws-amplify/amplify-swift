//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// User attributes and password change, with the plugin's semantics, for this session's user only.
///
/// Each call uses this session's access token, refreshed first through the session's single refresh if it
/// needs it, and never changes the session's saved record or disturbs a sign-in waiting on a challenge. As
/// in the plugin, none validates its arguments: Cognito answers an empty one.
@_spi(AmplifyExperimental)
public extension AmplifyCognitoClient {

    /// The signed-in user's attributes.
    ///
    /// - Parameter options: Nothing yet; here so the call keeps the plugin's shape.
    /// - Throws: `AmplifyCognitoClientError.configuration` without a user pool; `.notSignedIn` for a signed-out, guest
    ///   or federated session, and while a sign-in waits on a challenge; `.sessionExpired` when the tokens
    ///   needed a refresh and the refresh token is no longer valid; `.storageUnavailable` if the session's
    ///   record could not be read; `.notAuthorized` when Cognito refuses the access token (revoked, for
    ///   one); `.service` for Cognito's other answers; `.unknown` if Cognito answers without attributes.
    func fetchUserAttributes(
        options: AmplifyCognitoClientFetchUserAttributesOptions = AmplifyCognitoClientFetchUserAttributesOptions()
    ) async throws -> [AmplifyCognitoClientUserAttribute] {
        let core = core
        return try await core.signedInOperation("fetch the user attributes") { engine, payload in
            try await engine.fetchUserAttributes(payload)
        }
    }

    /// Updates one of the signed-in user's attributes.
    ///
    /// - Returns: Whether it was updated, or the code to confirm it with.
    /// - Throws: as `fetchUserAttributes()`.
    func update(
        userAttribute: AmplifyCognitoClientUserAttribute,
        options: AmplifyCognitoClientUpdateUserAttributesOptions = AmplifyCognitoClientUpdateUserAttributesOptions()
    ) async throws -> AmplifyCognitoClientUpdateAttributeResult {
        let results = try await update(userAttributes: [userAttribute], options: options)
        guard let result = results[userAttribute.key] else {
            throw AmplifyCognitoClientError.unknown(
                "Attribute to be updated does not exist in the result",
                "Fetch the user's attributes to see whether the update was applied, then retry it if it was not."
            )
        }
        return result
    }

    /// Updates several of the signed-in user's attributes at once.
    ///
    /// - Returns: For each attribute, whether it was updated, or the code to confirm it with.
    /// - Throws: as `fetchUserAttributes()`.
    func update(
        userAttributes: [AmplifyCognitoClientUserAttribute],
        options: AmplifyCognitoClientUpdateUserAttributesOptions = AmplifyCognitoClientUpdateUserAttributesOptions()
    ) async throws -> [AmplifyCognitoClientUserAttributeKey: AmplifyCognitoClientUpdateAttributeResult] {
        let clientMetadata = options.clientMetadata
        let core = core
        return try await core.signedInOperation("update the user attributes") { engine, payload in
            try await engine.updateUserAttributes(payload, attributes: userAttributes, clientMetadata: clientMetadata)
        }
    }

    /// Sends a code to verify one of the signed-in user's attributes, such as `email`.
    ///
    /// - Returns: Where the code was sent.
    /// - Throws: as `fetchUserAttributes()`.
    func sendVerificationCode(
        forUserAttributeKey userAttributeKey: AmplifyCognitoClientUserAttributeKey,
        options: AmplifyCognitoClientSendVerificationCodeOptions = AmplifyCognitoClientSendVerificationCodeOptions()
    ) async throws -> AmplifyCognitoClientCodeDeliveryDetails {
        let clientMetadata = options.clientMetadata
        let core = core
        return try await core.signedInOperation("send a verification code") { engine, payload in
            try await engine.sendVerificationCode(payload, attributeKey: userAttributeKey, clientMetadata: clientMetadata)
        }
    }

    /// Confirms one of the signed-in user's attributes with the code Cognito sent.
    ///
    /// - Parameter options: Nothing yet; here so the call keeps the plugin's shape.
    /// - Throws: as `fetchUserAttributes()`; `.service(.codeMismatch, …)` for a wrong code.
    func confirm(
        userAttribute: AmplifyCognitoClientUserAttributeKey,
        confirmationCode: String,
        options: AmplifyCognitoClientConfirmUserAttributeOptions = AmplifyCognitoClientConfirmUserAttributeOptions()
    ) async throws {
        let core = core
        try await core.signedInOperation("confirm a user attribute") { engine, payload in
            try await engine.confirmUserAttribute(payload, attributeKey: userAttribute, confirmationCode: confirmationCode)
        }
    }

    /// Changes the signed-in user's password.
    ///
    /// - Parameter options: Nothing yet; here so the call keeps the plugin's shape.
    /// - Throws: as `fetchUserAttributes()`; `.notAuthorized` for a wrong old password.
    func update(
        oldPassword: String,
        to newPassword: String,
        options: AmplifyCognitoClientChangePasswordOptions = AmplifyCognitoClientChangePasswordOptions()
    ) async throws {
        let core = core
        try await core.signedInOperation("change the password") { engine, payload in
            try await engine.changePassword(payload, oldPassword: oldPassword, newPassword: newPassword)
        }
    }
}
