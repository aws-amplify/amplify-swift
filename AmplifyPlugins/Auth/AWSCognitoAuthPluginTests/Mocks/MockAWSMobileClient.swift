//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSMobileClient

class MockAWSMobileClient: AWSMobileClientBehavior {

    var signupMockResult: Result<SignUpResult, Error>?
    var confirmSignUpMockResult: Result<SignUpResult, Error>?
    var resendSignUpCodeMockResult: Result<SignUpResult, Error>?
    var signInMockResult: Result<SignInResult, Error>?
    var federatedSignInMockResult: Result<UserState, Error>?
    var showSignInMockResult: Result<UserState, Error>?
    var confirmSignInMockResult: Result<SignInResult, Error>?
    var signOutMockError: Error?
    var usernameMockResult: String?
    var usersubMockResult: String?

    var verifyUserAttributeMockResult: Result<UserCodeDeliveryDetails, Error>?
    var updateUserAttributesMockResult: Result<[UserCodeDeliveryDetails], Error>?
    var getUserAttributeMockResult: Result<[String: String], Error>?
    var confirmUserAttributeMockResult: Result<Void, Error>?
    var changePasswordMockResult: Result<Void, Error>?
    var forgotPasswordMockResult: Result<ForgotPasswordResult, Error>?
    var confirmForgotPasswordMockResult: Result<ForgotPasswordResult, Error>?

    var getIdentityIdMockResult: AWSTask<NSString>?
    var tokensMockResult: Result<Tokens, Error>?
    var awsCredentialsMockResult: Result<AWSCredentials, Error>?
    var getCurrentUserStateMockResult: UserState?

    var listDevicesMockResult: Result<ListDevicesResult, Error>?
    var forgetDeviceMockResult: Error?
    var forgetCurrentDeviceMockResult: Error?
    var rememberDeviceMockResult: Result<UpdateDeviceStatusResult, Error>?

    var mockCurrentUserState: UserState = .unknown

    func initialize() throws {
        fatalError()
    }

    func signUp(username: String,
                password: String,
                userAttributes: [String: String],
                validationData: [String: String],
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        prepareResult(mockResult: signupMockResult, completionHandler: completionHandler)
    }

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        prepareResult(mockResult: confirmSignUpMockResult, completionHandler: completionHandler)
    }

    func resendSignUpCode(username: String,
                          clientMetaData: [String: String],
                          completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        prepareResult(mockResult: resendSignUpCodeMockResult, completionHandler: completionHandler)
    }

    func signIn(username: String,
                password: String,
                validationData: [String: String]?,
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        prepareResult(mockResult: signInMockResult, completionHandler: completionHandler)
    }

    func federatedSignIn(providerName: String,
                         token: String,
                         federatedSignInOptions: FederatedSignInOptions,
                         completionHandler: @escaping ((UserState?, Error?) -> Void)) {
        prepareResult(mockResult: federatedSignInMockResult, completionHandler: completionHandler)
    }

    func showSignIn(navigationController: UINavigationController,
                    signInUIOptions: SignInUIOptions,
                    hostedUIOptions: HostedUIOptions?,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void) {
        prepareResult(mockResult: showSignInMockResult, completionHandler: completionHandler)
    }

    func confirmSignIn(challengeResponse: String,
                       userAttributes: [String: String],
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        prepareResult(mockResult: confirmSignInMockResult, completionHandler: completionHandler)
    }

    func signOut(options: SignOutOptions,
                 completionHandler: @escaping ((Error?) -> Void)) {
       completionHandler(signOutMockError)
    }

    func signOutLocally() {
        //Do nothing
    }

    func getUsername() -> String? {
        fatalError()
    }

    func getUserSub() -> String? {
        fatalError()
    }

    func verifyUserAttribute(attributeName: String,
                             clientMetaData: [String: String],
                             completionHandler: @escaping ((UserCodeDeliveryDetails?, Error?) -> Void)) {
        prepareResult(mockResult: verifyUserAttributeMockResult, completionHandler: completionHandler)
    }

    func updateUserAttributes(attributeMap: [String: String],
                              clientMetaData: [String: String],
                              completionHandler: @escaping (([UserCodeDeliveryDetails]?, Error?) -> Void)) {
        prepareResult(mockResult: updateUserAttributesMockResult, completionHandler: completionHandler)
    }

    func getUserAttributes(completionHandler: @escaping (([String: String]?, Error?) -> Void)) {
        prepareResult(mockResult: getUserAttributeMockResult, completionHandler: completionHandler)
    }

    func confirmUpdateUserAttributes(attributeName: String,
                                     code: String,
                                     completionHandler: @escaping ((Error?) -> Void)) {
        fatalError()
    }

    func changePassword(currentPassword: String,
                        proposedPassword: String,
                        completionHandler: @escaping ((Error?) -> Void)) {
        fatalError()
    }

    func forgotPassword(username: String,
                        clientMetaData: [String: String],
                        completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        fatalError()
    }

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               clientMetaData: [String: String],
                               completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        prepareResult(mockResult: confirmForgotPasswordMockResult, completionHandler: completionHandler)
    }

    func getIdentityId() -> AWSTask<NSString> {
        return getIdentityIdMockResult!
    }

    func getTokens(_ completionHandler: @escaping (Tokens?, Error?) -> Void) {
        prepareResult(mockResult: tokensMockResult, completionHandler: completionHandler)
    }

    func getAWSCredentials(_ completionHandler: @escaping (AWSCredentials?, Error?) -> Void) {
        prepareResult(mockResult: awsCredentialsMockResult, completionHandler: completionHandler)
    }

    func getCurrentUserState() -> UserState {
        return mockCurrentUserState
    }

    func listDevices(completionHandler: @escaping ((ListDevicesResult?, Error?) -> Void)) {
        prepareResult(mockResult: listDevicesMockResult, completionHandler: completionHandler)
    }

    func updateDeviceStatus(remembered: Bool,
                            completionHandler: @escaping ((UpdateDeviceStatusResult?, Error?) -> Void)) {
        prepareResult(mockResult: rememberDeviceMockResult, completionHandler: completionHandler)
    }

    func getDevice(_ completionHandler: @escaping ((Device?, Error?) -> Void)) {
        fatalError()
    }

    func forgetDevice(deviceId: String, completionHandler: @escaping ((Error?) -> Void)) {
        completionHandler(forgetDeviceMockResult)
    }

    func forgetCurrentDevice(_ completionHandler: @escaping ((Error?) -> Void)) {
        completionHandler(forgetCurrentDeviceMockResult)
    }

    func invalidateCachedTemporaryCredentials() {
        fatalError()
    }

    func addUserStateListener(_ object: AnyObject, _ callback: @escaping UserStateChangeCallback) {

    }

    func removeUserStateListener(_ object: AnyObject) {
        fatalError()
    }

    func releaseSignInWait() {
        fatalError()
    }

    func prepareResult<R, E>(mockResult: Result<R, E>?,
                             completionHandler: (R?, E?) -> Void) {
        guard let nonNilResult = mockResult else {
            completionHandler(nil, nil)
            return
        }

        switch nonNilResult {
        case .success(let result):
            completionHandler(result, nil)
        case .failure(let error):
            completionHandler(nil, error)
        }
    }
}
