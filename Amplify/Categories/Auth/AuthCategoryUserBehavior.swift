//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AuthCategoryUserBehavior: AnyObject {

    /// Returns the currently logged in user.
    ///
    func getCurrentUser() async -> AuthUser?

    /// Returns the currently logged in user with closure.
    ///
    func getCurrentUser(closure: @escaping (Result<AuthUser?, Error>) -> Void)

    /// Fetch user attributes for the current user.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func fetchUserAttributes(options: AuthFetchUserAttributeOperation.Request.Options?,
                             listener: AuthFetchUserAttributeOperation.ResultListener?)
        -> AuthFetchUserAttributeOperation

    /// Update user attribute for the current user
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute that need to be updated
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func update(userAttribute: AuthUserAttribute,
                options: AuthUpdateUserAttributeOperation.Request.Options?,
                listener: AuthUpdateUserAttributeOperation.ResultListener?) -> AuthUpdateUserAttributeOperation

    /// Update a list of user attributes for the current user
    ///
    /// - Parameters:
    ///   - userAttributes: List of attribtues that need ot be updated
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func update(userAttributes: [AuthUserAttribute],
                options: AuthUpdateUserAttributesOperation.Request.Options?,
                listener: AuthUpdateUserAttributesOperation.ResultListener?) -> AuthUpdateUserAttributesOperation

    /// Resends the confirmation code required to verify an attribute
    ///
    /// - Parameters:
    ///   - attributeKey: Attribute to be verified
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                options: AuthAttributeResendConfirmationCodeOperation.Request.Options?,
                                listener: AuthAttributeResendConfirmationCodeOperation.ResultListener?)
        -> AuthAttributeResendConfirmationCodeOperation

    /// Confirm an attribute using confirmation code
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute to verify
    ///   - confirmationCode: Confirmation code received
    ///   - options: Parameters specific to plugin behavior
    ///   - listener: Triggered when the operation completes.
    @discardableResult
    func confirm(userAttribute: AuthUserAttributeKey,
                 confirmationCode: String,
                 options: AuthConfirmUserAttributeOperation.Request.Options?,
                 listener: AuthConfirmUserAttributeOperation.ResultListener?) -> AuthConfirmUserAttributeOperation

    /// Update the current logged in user's password
    ///
    /// Check the plugins documentation, you might need to re-authenticate the user after calling this method.
    /// - Parameters:
    ///   - oldPassword: Current password of the user
    ///   - newPassword: New password to be updated
    ///   - options: Parameters specific to plugin behavior
    func update(oldPassword: String, to newPassword: String, options: AuthChangePasswordRequest.Options?) async throws
}
