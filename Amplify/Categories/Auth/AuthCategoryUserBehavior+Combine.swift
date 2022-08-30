//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// No-listener versions of the public APIs, to clean call sites that use Combine
// publishers to get results

public extension AuthCategoryUserBehavior {

    /// Fetch user attributes for the current user.
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    func fetchUserAttributes(
        options: AuthFetchUserAttributeOperation.Request.Options? = nil
    ) -> AuthFetchUserAttributeOperation {
        fetchUserAttributes(options: options, listener: nil)
    }

    /// Update user attribute for the current user
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute that need to be updated
    ///   - options: Parameters specific to plugin behavior
    func update(
        userAttribute: AuthUserAttribute,
        options: AuthUpdateUserAttributeOperation.Request.Options? = nil
    ) -> AuthUpdateUserAttributeOperation {
        update(userAttribute: userAttribute, options: options, listener: nil)
    }

    /// Update a list of user attributes for the current user
    ///
    /// - Parameters:
    ///   - userAttributes: List of attribtues that need ot be updated
    ///   - options: Parameters specific to plugin behavior
    func update(
        userAttributes: [AuthUserAttribute],
        options: AuthUpdateUserAttributesOperation.Request.Options? = nil
    ) -> AuthUpdateUserAttributesOperation {
        update(userAttributes: userAttributes, options: options, listener: nil)
    }

    /// Resends the confirmation code required to verify an attribute
    ///
    /// - Parameters:
    ///   - attributeKey: Attribute to be verified
    ///   - options: Parameters specific to plugin behavior
    func resendConfirmationCode(
        for attributeKey: AuthUserAttributeKey,
        options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil
    ) -> AuthAttributeResendConfirmationCodeOperation {
        resendConfirmationCode(for: attributeKey, options: options, listener: nil)
    }

    /// Confirm an attribute using confirmation code
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute to verify
    ///   - confirmationCode: Confirmation code received
    ///   - options: Parameters specific to plugin behavior
    func confirm(
        userAttribute: AuthUserAttributeKey,
        confirmationCode: String,
        options: AuthConfirmUserAttributeOperation.Request.Options? = nil
    ) -> AuthConfirmUserAttributeOperation {
        confirm(
            userAttribute: userAttribute,
            confirmationCode: confirmationCode,
            options: options,
            listener: nil
        )
    }
}
