//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryUserBehavior {

    public func getCurrentUser() async -> AuthUser? {
        return await plugin.getCurrentUser()
    }

    public func fetchUserAttributes(options: AuthFetchUserAttributesRequest.Options? = nil) async throws -> [AuthUserAttribute] {
        return try await plugin.fetchUserAttributes(options: options)
    }

    public func update(userAttribute: AuthUserAttribute, options: AuthUpdateUserAttributeRequest.Options? = nil) async throws -> AuthUpdateAttributeResult {
        return try await plugin.update(userAttribute: userAttribute, options: options)
    }

    public func update(userAttributes: [AuthUserAttribute],
                       options: AuthUpdateUserAttributesRequest.Options? = nil)
        async throws -> [AuthUserAttributeKey: AuthUpdateAttributeResult] {
            return try await plugin.update(userAttributes: userAttributes, options: options)
    }

    public func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                       options: AuthAttributeResendConfirmationCodeRequest.Options? = nil) async throws -> AuthCodeDeliveryDetails {
        return try await plugin.resendConfirmationCode(for: attributeKey, options: options)

    }

    public func confirm(userAttribute: AuthUserAttributeKey,
                        confirmationCode: String,
                        options: AuthConfirmUserAttributeRequest.Options? = nil) async throws {
        try await plugin.confirm(userAttribute: userAttribute, confirmationCode: confirmationCode, options: options)
    }

    public func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options? = nil) async throws {
        try await plugin.update(oldPassword: oldPassword, to: newPassword, options: options)
    }

}
