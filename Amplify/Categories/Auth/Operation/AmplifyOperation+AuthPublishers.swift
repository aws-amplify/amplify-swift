//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

// MARK: - AuthAttributeResendConfirmationCodeOperation

// The overrides require a feature and bugfix introduced in Swift 5.2
#if swift(>=5.2)

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthAttributeResendConfirmationCodeOperation.Request,
    Success == AuthAttributeResendConfirmationCodeOperation.Success,
    Failure == AuthAttributeResendConfirmationCodeOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthChangePasswordOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthChangePasswordOperation.Request,
    Success == AuthChangePasswordOperation.Success,
    Failure == AuthChangePasswordOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthConfirmResetPasswordOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthConfirmResetPasswordOperation.Request,
    Success == AuthConfirmResetPasswordOperation.Success,
    Failure == AuthConfirmResetPasswordOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthConfirmSignInOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthConfirmSignInOperation.Request,
    Success == AuthConfirmSignInOperation.Success,
    Failure == AuthConfirmSignInOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthConfirmSignUpOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthConfirmSignUpOperation.Request,
    Success == AuthConfirmSignUpOperation.Success,
    Failure == AuthConfirmSignUpOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthConfirmUserAttributeOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthConfirmUserAttributeOperation.Request,
    Success == AuthConfirmUserAttributeOperation.Success,
    Failure == AuthConfirmUserAttributeOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthFetchDevicesOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthFetchDevicesOperation.Request,
    Success == AuthFetchDevicesOperation.Success,
    Failure == AuthFetchDevicesOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthFetchSessionOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthFetchSessionOperation.Request,
    Success == AuthFetchSessionOperation.Success,
    Failure == AuthFetchSessionOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthFetchUserAttributeOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthFetchUserAttributeOperation.Request,
    Success == AuthFetchUserAttributeOperation.Success,
    Failure == AuthFetchUserAttributeOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthForgetDeviceOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthForgetDeviceOperation.Request,
    Success == AuthForgetDeviceOperation.Success,
    Failure == AuthForgetDeviceOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthRememberDeviceOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthRememberDeviceOperation.Request,
    Success == AuthRememberDeviceOperation.Success,
    Failure == AuthRememberDeviceOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthResendSignUpCodeOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthResendSignUpCodeOperation.Request,
    Success == AuthResendSignUpCodeOperation.Success,
    Failure == AuthResendSignUpCodeOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthResetPasswordOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthResetPasswordOperation.Request,
    Success == AuthResetPasswordOperation.Success,
    Failure == AuthResetPasswordOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthSignInOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthSignInOperation.Request,
    Success == AuthSignInOperation.Success,
    Failure == AuthSignInOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthSignOutOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthSignOutOperation.Request,
    Success == AuthSignOutOperation.Success,
    Failure == AuthSignOutOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthDeleteUserOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthDeleteUserOperation.Request,
    Success == AuthDeleteUserOperation.Success,
    Failure == AuthDeleteUserOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthSignUpOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthSignUpOperation.Request,
    Success == AuthSignUpOperation.Success,
    Failure == AuthSignUpOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthSocialWebUISignInOperation and AuthWebUISignInOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthSocialWebUISignInOperation.Request,
    Success == AuthSocialWebUISignInOperation.Success,
    Failure == AuthSocialWebUISignInOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthUpdateUserAttributeOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthUpdateUserAttributeOperation.Request,
    Success == AuthUpdateUserAttributeOperation.Success,
    Failure == AuthUpdateUserAttributeOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

// MARK: - AuthUpdateUserAttributesOperation

@available(iOS 13.0, *)
public extension AmplifyOperation
    where
    Request == AuthUpdateUserAttributesOperation.Request,
    Success == AuthUpdateUserAttributesOperation.Success,
    Failure == AuthUpdateUserAttributesOperation.Failure {
    /// Publishes the result of the operation
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
}

#endif
