//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

public extension AuthCategoryUserBehavior {

    /// Confirm an attribute using confirmation code
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute to verify
    ///   - confirmationCode: Confirmation code received
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func confirm(
        userAttribute: AuthUserAttributeKey,
        confirmationCode: String,
        options: AuthConfirmUserAttributeOperation.Request.Options? = nil
    ) -> AuthPublisher<Void> {
        Future { promise in
            _ = self.confirm(
                userAttribute: userAttribute,
                confirmationCode: confirmationCode,
                options: options
            ) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Fetch user attributes for the current user
    ///
    /// - Parameters:
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func fetchUserAttributes(
        options: AuthFetchUserAttributeOperation.Request.Options? = nil
    ) -> AuthPublisher<[AuthUserAttribute]> {
        Future { promise in
            _ = self.fetchUserAttributes(options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Resends the confirmation code required to verify an attribute
    ///
    /// - Parameters:
    ///   - attributeKey: Attribute to be verified
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func resendConfirmationCode(
        for attributeKey: AuthUserAttributeKey,
        options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil
    ) -> AuthPublisher<AuthCodeDeliveryDetails> {
        Future { promise in
            _ = self.resendConfirmationCode(for: attributeKey, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Update the current logged in user's password
    ///
    /// Check the plugins documentation, you might need to re-authenticate the user after calling this method.
    /// - Parameters:
    ///   - oldPassword: Current password of the user
    ///   - newPassword: New password to be updated
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func update(
        oldPassword: String,
        to newPassword: String,
        options: AuthChangePasswordOperation.Request.Options? = nil
    ) -> AuthPublisher<Void> {
        Future { promise in
            _ = self.update(oldPassword: oldPassword, to: newPassword, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Update user attribute for the current user
    ///
    /// - Parameters:
    ///   - userAttribute: Attribute that need to be updated
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func update(
        userAttribute: AuthUserAttribute,
        options: AuthUpdateUserAttributeOperation.Request.Options? = nil
    ) -> AuthPublisher<AuthUpdateAttributeResult> {
        Future { promise in
            _ = self.update(userAttribute: userAttribute, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Update a list of user attributes for the current user
    ///
    /// - Parameters:
    ///   - userAttributes: List of attribtues that need ot be updated
    ///   - options: Parameters specific to plugin behavior
    /// - Returns: An AuthPublisher with the results of the operation
    func update(
        userAttributes: [AuthUserAttribute],
        options: AuthUpdateUserAttributesOperation.Request.Options? = nil
    ) -> AuthPublisher<[AuthUserAttributeKey: AuthUpdateAttributeResult]> {
        Future { promise in
            _ = self.update(userAttributes: userAttributes, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

}
