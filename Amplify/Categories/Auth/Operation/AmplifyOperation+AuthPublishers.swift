//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Foundation
import Combine

// MARK: - AuthAttributeResendConfirmationCodeOperation

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

#if canImport(UIKit)
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
#endif

// MARK: - AuthUpdateUserAttributeOperation

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
