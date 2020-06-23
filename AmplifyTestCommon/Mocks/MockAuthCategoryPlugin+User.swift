//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension MockAuthCategoryPlugin {

    public func confirm(
        userAttribute: AuthUserAttributeKey,
        confirmationCode: String,
        options: AuthConfirmUserAttributeOperation.Request.Options? = nil,
        listener: AuthConfirmUserAttributeOperation.ResultListener?
    ) -> AuthConfirmUserAttributeOperation {
        notify()
        if let responder = responders.confirmUserAttribute {
            let result = responder(userAttribute, confirmationCode, options)
            listener?(result)
        }
        let request = AuthConfirmUserAttributeOperation.Request(
            attributeKey: userAttribute,
            confirmationCode: confirmationCode,
            options: options ?? AuthConfirmUserAttributeOperation.Request.Options()
        )
        return MockAuthConfirmUserAttributeOperation(request: request)
    }

    public func fetchUserAttributes(
        options: AuthFetchUserAttributeOperation.Request.Options? = nil,
        listener: AuthFetchUserAttributeOperation.ResultListener?
    ) -> AuthFetchUserAttributeOperation {
        notify()
        if let responder = responders.fetchUserAttributes {
            let result = responder(options)
            listener?(result)
        }
        let request = AuthFetchUserAttributeOperation.Request(
            options: options ?? AuthFetchUserAttributeOperation.Request.Options()
        )
        return MockAuthFetchUserAttributeOperation(request: request)
    }

    public func getCurrentUser() -> AuthUser? {
        fatalError()
    }

    public func resendConfirmationCode(
        for attributeKey: AuthUserAttributeKey,
        options: AuthAttributeResendConfirmationCodeOperation.Request.Options? = nil,
        listener: AuthAttributeResendConfirmationCodeOperation.ResultListener?
    ) -> AuthAttributeResendConfirmationCodeOperation {
        notify()
        if let responder = responders.resendConfirmationCode {
            let result = responder(attributeKey, options)
            listener?(result)
        }
        let request = AuthAttributeResendConfirmationCodeOperation.Request(
            attributeKey: attributeKey,
            options: options ?? AuthAttributeResendConfirmationCodeOperation.Request.Options()
        )
        return MockAuthAttributeResendConfirmationCodeOperation(request: request)
    }

    public func update(
        oldPassword: String,
        to newPassword: String,
        options: AuthChangePasswordOperation.Request.Options? = nil,
        listener: AuthChangePasswordOperation.ResultListener?
    ) -> AuthChangePasswordOperation {
        notify()
        if let responder = responders.updatePassword {
            let result = responder(oldPassword, newPassword, options)
            listener?(result)
        }
        let request = AuthChangePasswordOperation.Request(
            oldPassword: oldPassword,
            newPassword: newPassword,
            options: options ?? AuthChangePasswordOperation.Request.Options()
        )
        return MockAuthChangePasswordOperation(request: request)
    }

    public func update(
        userAttribute: AuthUserAttribute,
        options: AuthUpdateUserAttributeOperation.Request.Options? = nil,
        listener: AuthUpdateUserAttributeOperation.ResultListener?
    ) -> AuthUpdateUserAttributeOperation {
        notify()
        if let responder = responders.updateUserAttribute {
            let result = responder(userAttribute, options)
            listener?(result)
        }
        let request = AuthUpdateUserAttributeOperation.Request(
            userAttribute: userAttribute,
            options: options ?? AuthUpdateUserAttributeOperation.Request.Options()
        )
        return MockAuthUpdateUserAttributeOperation(request: request)
    }

    public func update(
        userAttributes: [AuthUserAttribute],
        options: AuthUpdateUserAttributesOperation.Request.Options? = nil,
        listener: AuthUpdateUserAttributesOperation.ResultListener?
    ) -> AuthUpdateUserAttributesOperation {
        notify()
        if let responder = responders.updateUserAttributes {
            let result = responder(userAttributes, options)
            listener?(result)
        }
        let request = AuthUpdateUserAttributesOperation.Request(
            userAttributes: userAttributes,
            options: options ?? AuthUpdateUserAttributesOperation.Request.Options()
        )
        return MockAuthUpdateUserAttributesOperation(request: request)
    }

}
