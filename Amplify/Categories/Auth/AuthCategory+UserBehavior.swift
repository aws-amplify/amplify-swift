//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthCategory: AuthCategoryUserBehavior {

    public func getCurrentUser() -> AuthUser? {
        return plugin.getCurrentUser()
    }

    @discardableResult
    public func fetchUserAttributes(options: AuthFetchUserAttributeOperation.Request.Options? = nil,
                                    listener: AuthFetchUserAttributeOperation.ResultListener?)
        -> AuthFetchUserAttributeOperation {
            return plugin.fetchUserAttributes(options: options,
                                              listener: listener)
    }

    @discardableResult
    public func update(userAttribute: AuthUserAttribute,
                       options: AuthUpdateUserAttributeOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributeOperation.ResultListener?) -> AuthUpdateUserAttributeOperation {
        return plugin.update(userAttribute: userAttribute,
                             options: options,
                             listener: listener)
    }

    @discardableResult
    public func update(userAttributes: [AuthUserAttribute],
                       options: AuthUpdateUserAttributesOperation.Request.Options? = nil,
                       listener: AuthUpdateUserAttributesOperation.ResultListener?)
        -> AuthUpdateUserAttributesOperation {
            return plugin.update(userAttributes: userAttributes,
                                 options: options,
                                 listener: listener)
    }

    @discardableResult
    public func resendConfirmationCode(for attributeKey: AuthUserAttributeKey,
                                       options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil,
                                       listener: AuthAttributeResendConfirmationCodeOperation.ResultListener?)
        -> AuthAttributeResendConfirmationCodeOperation {
            return plugin.resendConfirmationCode(for: attributeKey,
                                                 options: options,
                                                 listener: listener)

    }

    @discardableResult
    public func confirm(userAttribute: AuthUserAttributeKey,
                        confirmationCode: String,
                        options: AuthConfirmUserAttributeOperation.Request.Options? = nil,
                        listener: AuthConfirmUserAttributeOperation.ResultListener?)
        -> AuthConfirmUserAttributeOperation {
            return plugin.confirm(userAttribute: userAttribute,
                                  confirmationCode: confirmationCode,
                                  options: options,
                                  listener: listener)
    }

    @discardableResult
    public func update(oldPassword: String,
                       to newPassword: String,
                       options: AuthChangePasswordOperation.Request.Options? = nil,
                       listener: AuthChangePasswordOperation.ResultListener?) -> AuthChangePasswordOperation {
        return plugin.update(oldPassword: oldPassword,
                             to: newPassword,
                             options: options,
                             listener: listener)
    }

}
