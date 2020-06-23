//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

// MARK: - AuthN

class MockAuthConfirmResetPasswordOperation: AmplifyOperation<
    AuthConfirmResetPasswordRequest,
    Void,
    AuthError
>, AuthConfirmResetPasswordOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmResetPasswordAPI,
                   request: request)
    }
}

class MockAuthConfirmSignInOperation: AmplifyOperation<
    AuthConfirmSignInRequest,
    AuthSignInResult,
    AuthError
>, AuthConfirmSignInOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmSignInAPI,
                   request: request)
    }
}

class MockAuthConfirmSignUpOperation: AmplifyOperation<
    AuthConfirmSignUpRequest,
    AuthSignUpResult,
    AuthError
>, AuthConfirmSignUpOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmSignUpAPI,
                   request: request)
    }
}

class MockAuthFetchSessionOperation: AmplifyOperation<
    AuthFetchSessionRequest,
    AuthSession,
    AuthError
>, AuthFetchSessionOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchSessionAPI,
                   request: request)
    }
}

class MockAuthResendSignUpCodeOperation: AmplifyOperation<
    AuthResendSignUpCodeRequest,
    AuthCodeDeliveryDetails,
    AuthError
>, AuthResendSignUpCodeOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resendSignUpCodeAPI,
                   request: request)
    }
}

class MockAuthResetPasswordOperation: AmplifyOperation<
    AuthResetPasswordRequest,
    AuthResetPasswordResult,
    AuthError
>, AuthResetPasswordOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.resetPasswordAPI,
                   request: request)
    }
}

class MockAuthSignInOperation: AmplifyOperation<
    AuthSignInRequest,
    AuthSignInResult,
    AuthError
>, AuthSignInOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signInAPI,
                   request: request)
    }
}

class MockAuthWebUISignInOperation: AmplifyOperation<
    AuthWebUISignInRequest,
    AuthSignInResult,
    AuthError
>, AuthWebUISignInOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.webUISignInAPI,
                   request: request)
    }
}

class MockAuthSocialWebUISignInOperation: AmplifyOperation<
    AuthWebUISignInRequest,
    AuthSignInResult,
    AuthError
>, AuthSocialWebUISignInOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.socialWebUISignInAPI,
                   request: request)
    }
}

class MockAuthSignOutOperation: AmplifyOperation<
    AuthSignOutRequest,
    Void,
    AuthError
>, AuthSignOutOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signOutAPI,
                   request: request)
    }
}

class MockAuthSignUpOperation: AmplifyOperation<
    AuthSignUpRequest,
    AuthSignUpResult,
    AuthError
>, AuthSignUpOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.signUpAPI,
                   request: request)
    }
}

// MARK: - Device

class MockAuthFetchDevicesOperation: AmplifyOperation<
    AuthFetchDevicesRequest,
    [AuthDevice],
    AuthError
>, AuthFetchDevicesOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchDevicesAPI,
                   request: request)
    }
}

class MockAuthForgetDeviceOperation: AmplifyOperation<
    AuthForgetDeviceRequest,
    Void,
    AuthError
>, AuthForgetDeviceOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.forgetDeviceAPI,
                   request: request)
    }
}

class MockAuthRememberDeviceOperation: AmplifyOperation<
    AuthRememberDeviceRequest,
    Void,
    AuthError
>, AuthRememberDeviceOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.rememberDeviceAPI,
                   request: request)
    }
}

// MARK: - User

class MockAuthConfirmUserAttributeOperation: AmplifyOperation<
    AuthConfirmUserAttributeRequest,
    Void,
    AuthError
>, AuthConfirmUserAttributeOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.confirmUserAttributesAPI,
                   request: request)
    }
}

class MockAuthFetchUserAttributeOperation: AmplifyOperation<
    AuthFetchUserAttributesRequest,
    [AuthUserAttribute],
    AuthError
>, AuthFetchUserAttributeOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.fetchUserAttributesAPI,
                   request: request)
    }
}

// swiftlint:disable:next type_name
class MockAuthAttributeResendConfirmationCodeOperation: AmplifyOperation<
    AuthAttributeResendConfirmationCodeRequest,
    AuthCodeDeliveryDetails,
    AuthError
>, AuthAttributeResendConfirmationCodeOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.attributeResendConfirmationCodeAPI,
                   request: request)
    }
}

class MockAuthChangePasswordOperation: AmplifyOperation<
    AuthChangePasswordRequest,
    Void,
    AuthError
>, AuthChangePasswordOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.changePasswordAPI,
                   request: request)
    }
}

class MockAuthUpdateUserAttributeOperation: AmplifyOperation<
    AuthUpdateUserAttributeRequest,
    AuthUpdateAttributeResult,
    AuthError
>, AuthUpdateUserAttributeOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.updateUserAttributeAPI,
                   request: request)
    }
}

class MockAuthUpdateUserAttributesOperation: AmplifyOperation<
    AuthUpdateUserAttributesRequest,
    [AuthUserAttributeKey: AuthUpdateAttributeResult],
    AuthError
>, AuthUpdateUserAttributesOperation {
    init(request: Request) {
        super.init(categoryType: .auth,
                   eventName: HubPayload.EventName.Auth.updateUserAttributesAPI,
                   request: request)
    }
}
