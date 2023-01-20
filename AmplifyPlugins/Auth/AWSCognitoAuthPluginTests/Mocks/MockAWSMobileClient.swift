//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import AWSMobileClient

class MockAWSMobileClient: AWSMobileClientBehavior {

    var interactions: [String] = []

    var signupMockResult: Result<SignUpResult, Error>?
    var confirmSignUpMockResult: Result<SignUpResult, Error>?
    var resendSignUpCodeMockResult: Result<SignUpResult, Error>?
    var signInMockResult: Result<SignInResult, Error>?
    var federatedSignInMockResult: Result<UserState, Error>?
    var showSignInMockResult: Result<UserState, Error>?
    var confirmSignInMockResult: Result<SignInResult, Error>?
    var signOutMockError: Error?
    var deleteUserMockError: Error?
    var usernameMockResult: String?
    var usersubMockResult: String?

    var verifyUserAttributeMockResult: Result<UserCodeDeliveryDetails, Error>?
    var updateUserAttributesMockResult: Result<[UserCodeDeliveryDetails], Error>?
    var getUserAttributeMockResult: Result<[String: String], Error>?
    var confirmUserAttributeMockResult: Error?
    var changePasswordMockResult: Error?
    var forgotPasswordMockResult: Result<ForgotPasswordResult, Error>?
    var confirmForgotPasswordMockResult: Result<ForgotPasswordResult, Error>?

    var getIdentityIdMockResult: AWSTask<NSString> = AWSTask(result: UUID().uuidString as NSString)
    var tokensMockResult: Result<Tokens, Error>?
    var awsCredentialsMockResult: Result<AWSCredentials, Error>?
    var getCurrentUserStateMockResult: UserState?

    var listDevicesMockResult: Result<ListDevicesResult, Error>?
    var forgetDeviceMockResult: Error?
    var forgetCurrentDeviceMockResult: Error?
    var rememberDeviceMockResult: Result<UpdateDeviceStatusResult, Error>?

    var mockCurrentUserState: UserState = .unknown

    func initialize() throws {
        interactions.append(#function)
    }

    func signOut(uiwindow: UIWindow, options: SignOutOptions, completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
    }

    func signUp(username: String,
                password: String,
                userAttributes: [String: String],
                validationData: [String: String],
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: signupMockResult, completionHandler: completionHandler)
    }

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: confirmSignUpMockResult, completionHandler: completionHandler)
    }

    func resendSignUpCode(username: String,
                          clientMetaData: [String: String],
                          completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: resendSignUpCodeMockResult, completionHandler: completionHandler)
    }

    func signIn(username: String,
                password: String,
                validationData: [String: String]?,
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: signInMockResult, completionHandler: completionHandler)
    }

    func federatedSignIn(providerName: String,
                         token: String,
                         federatedSignInOptions: FederatedSignInOptions,
                         completionHandler: @escaping ((UserState?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: federatedSignInMockResult, completionHandler: completionHandler)
    }

    func showSignIn(navigationController: UINavigationController,
                    signInUIOptions: SignInUIOptions,
                    hostedUIOptions: HostedUIOptions?,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void) {
        interactions.append(#function)
        prepareResult(mockResult: showSignInMockResult, completionHandler: completionHandler)
    }

    func showSignIn(uiwindow: UIWindow,
                    hostedUIOptions: HostedUIOptions,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void) {
        interactions.append(#function)
        prepareResult(mockResult: showSignInMockResult, completionHandler: completionHandler)
    }

    func confirmSignIn(challengeResponse: String,
                       userAttributes: [String: String],
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: confirmSignInMockResult, completionHandler: completionHandler)
    }

    func signOut(options: SignOutOptions,
                 completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
       completionHandler(signOutMockError)
    }

    func signOutLocally() {
        interactions.append(#function)
    }

    func deleteUser(completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
       completionHandler(deleteUserMockError)
    }

    var username: String?

    func getUsername() -> String? {
        interactions.append(#function)
        return username
    }

    var userSub: String?

    func getUserSub() -> String? {
        interactions.append(#function)
        return userSub
    }

    func verifyUserAttribute(attributeName: String,
                             clientMetaData: [String: String],
                             completionHandler: @escaping ((UserCodeDeliveryDetails?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: verifyUserAttributeMockResult, completionHandler: completionHandler)
    }

    func updateUserAttributes(attributeMap: [String: String],
                              clientMetaData: [String: String],
                              completionHandler: @escaping (([UserCodeDeliveryDetails]?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: updateUserAttributesMockResult, completionHandler: completionHandler)
    }

    func getUserAttributes(completionHandler: @escaping (([String: String]?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: getUserAttributeMockResult, completionHandler: completionHandler)
    }

    func confirmUpdateUserAttributes(attributeName: String,
                                     code: String,
                                     completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
        completionHandler(confirmUserAttributeMockResult)
    }

    func changePassword(currentPassword: String,
                        proposedPassword: String,
                        completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
        completionHandler(changePasswordMockResult)
    }

    func forgotPassword(username: String,
                        clientMetaData: [String: String],
                        completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: forgotPasswordMockResult, completionHandler: completionHandler)
    }

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               clientMetaData: [String: String],
                               completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: confirmForgotPasswordMockResult, completionHandler: completionHandler)
    }

    func getIdentityId() -> AWSTask<NSString> {
        interactions.append(#function)
        return getIdentityIdMockResult
    }

    func getTokens(_ completionHandler: @escaping (Tokens?, Error?) -> Void) {
        interactions.append(#function)
        prepareResult(mockResult: tokensMockResult, completionHandler: completionHandler)
    }

    func getAWSCredentials(_ completionHandler: @escaping (AWSCredentials?, Error?) -> Void) {
        interactions.append(#function)
        prepareResult(mockResult: awsCredentialsMockResult, completionHandler: completionHandler)
    }

    func getCurrentUserState() -> UserState {
        interactions.append(#function)
        return mockCurrentUserState
    }

    func listDevices(completionHandler: @escaping ((ListDevicesResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: listDevicesMockResult, completionHandler: completionHandler)
    }

    func updateDeviceStatus(remembered: Bool,
                            completionHandler: @escaping ((UpdateDeviceStatusResult?, Error?) -> Void)) {
        interactions.append(#function)
        prepareResult(mockResult: rememberDeviceMockResult, completionHandler: completionHandler)
    }

    func getDevice(_ completionHandler: @escaping ((Device?, Error?) -> Void)) {
        interactions.append(#function)
        completionHandler(nil, nil)
    }

    func forgetDevice(deviceId: String, completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
        completionHandler(forgetDeviceMockResult)
    }

    func forgetCurrentDevice(_ completionHandler: @escaping ((Error?) -> Void)) {
        interactions.append(#function)
        completionHandler(forgetCurrentDeviceMockResult)
    }

    func invalidateCachedTemporaryCredentials() {
        interactions.append(#function)
    }

    func addUserStateListener(_ object: AnyObject, _ callback: @escaping UserStateChangeCallback) {
        interactions.append(#function)
    }

    func removeUserStateListener(_ object: AnyObject) {
        interactions.append(#function)
    }

    func releaseSignInWait() {
        interactions.append(#function)
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
