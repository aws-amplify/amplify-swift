//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

class AWSMobileClientAdapter: AWSMobileClientBehavior {

    let awsMobileClient: AWSMobileClient

    init(userPoolConfiguration: AmplifyAWSServiceConfiguration?,
         identityPoolConfiguration: AmplifyAWSServiceConfiguration?) {

        AWSMobileClient.updateCognitoService(userPoolConfiguration: userPoolConfiguration,
                                             identityPoolConfiguration: identityPoolConfiguration)
        self.awsMobileClient = AWSMobileClient.default()
    }

    func initialize() throws {

        var mobileClientError: Error?

        awsMobileClient.initialize { _, error in
            mobileClientError = error
        }
        if let error = mobileClientError {
            throw AuthError.configuration(
                AuthPluginErrorConstants.mobileClientInitializeError.errorDescription,
                AuthPluginErrorConstants.mobileClientInitializeError.recoverySuggestion,
                error)
        }
    }

    func signUp(username: String,
                password: String,
                userAttributes: [String: String] = [:],
                validationData: [String: String] = [:],
                clientMetaData: [String: String] = [:],
                completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {

        awsMobileClient.signUp(username: username,
                               password: password,
                               userAttributes: userAttributes,
                               validationData: validationData,
                               clientMetaData: clientMetaData,
                               completionHandler: completionHandler)
    }

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       clientMetaData: [String: String] = [:],
                       completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        awsMobileClient.confirmSignUp(username: username,
                                      confirmationCode: confirmationCode,
                                      clientMetaData: clientMetaData,
                                      completionHandler: completionHandler)
    }

    func resendSignUpCode(username: String,
                          clientMetaData: [String: String],
                          completionHandler: @escaping ((SignUpResult?, Error?) -> Void)) {
        awsMobileClient.resendSignUpCode(username: username,
                                         clientMetaData: clientMetaData,
                                         completionHandler: completionHandler)
    }

    func signIn(username: String,
                password: String,
                validationData: [String: String]? = nil,
                clientMetaData: [String: String] = [:],
                completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        awsMobileClient.signIn(username: username,
                               password: password,
                               validationData: validationData,
                               clientMetaData: clientMetaData,
                               completionHandler: completionHandler)
    }

    func federatedSignIn(providerName: String, token: String,
                         federatedSignInOptions: FederatedSignInOptions,
                         completionHandler: @escaping ((UserState?, Error?) -> Void)) {
        awsMobileClient.federatedSignIn(providerName: providerName,
                                        token: token,
                                        federatedSignInOptions: federatedSignInOptions,
                                        completionHandler: completionHandler)
    }

    func showSignIn(navigationController: UINavigationController,
                    signInUIOptions: SignInUIOptions,
                    hostedUIOptions: HostedUIOptions?,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void) {
        awsMobileClient.showSignIn(navigationController: navigationController,
                                   signInUIOptions: signInUIOptions,
                                   hostedUIOptions: hostedUIOptions,
                                   completionHandler)
    }

    @available(iOS 13, *)
    func showSignIn(uiwindow: UIWindow,
                    hostedUIOptions: HostedUIOptions,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void) {
        awsMobileClient.showSignIn(presentationAnchor: uiwindow,
                                   hostedUIOptions: hostedUIOptions,
                                   completionHandler)
    }

    func confirmSignIn(challengeResponse: String,
                       userAttributes: [String: String] = [:],
                       clientMetaData: [String: String] = [:],
                       completionHandler: @escaping ((SignInResult?, Error?) -> Void)) {
        awsMobileClient.confirmSignIn(challengeResponse: challengeResponse,
                                      userAttributes: userAttributes,
                                      clientMetaData: clientMetaData,
                                      completionHandler: completionHandler)
    }

    func signOut(options: SignOutOptions = SignOutOptions(), completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.signOut(options: options, completionHandler: completionHandler)
    }

    @available(iOS 13, *)
    func signOut(uiwindow: UIWindow,
                 options: SignOutOptions = SignOutOptions(),
                 completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.signOut(presentationAnchor: uiwindow,
                                options: options,
                                completionHandler: completionHandler)
    }

    func signOutLocally() {
        awsMobileClient.signOut()
    }

    func deleteUser(completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.deleteUser(completionHandler: completionHandler)
    }

    func getUsername() -> String? {
        return awsMobileClient.username
    }

    func getUserSub() -> String? {
        return awsMobileClient.userSub
    }

    func verifyUserAttribute(attributeName: String,
                             clientMetaData: [String: String] = [:],
                             completionHandler: @escaping ((UserCodeDeliveryDetails?, Error?) -> Void)) {
        awsMobileClient.verifyUserAttribute(attributeName: attributeName,
                                            clientMetaData: clientMetaData,
                                            completionHandler: completionHandler)
    }

    func updateUserAttributes(attributeMap: [String: String],
                              clientMetaData: [String: String] = [:],
                              completionHandler: @escaping (([UserCodeDeliveryDetails]?, Error?) -> Void)) {
        awsMobileClient.updateUserAttributes(attributeMap: attributeMap,
                                             clientMetaData: clientMetaData,
                                             completionHandler: completionHandler)
    }

    func getUserAttributes(completionHandler: @escaping (([String: String]?, Error?) -> Void)) {
        awsMobileClient.getUserAttributes(completionHandler: completionHandler)
    }

    func confirmUpdateUserAttributes(attributeName: String, code: String,
                                     completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.confirmUpdateUserAttributes(attributeName: attributeName,
                                                    code: code,
                                                    completionHandler: completionHandler)
    }

    func changePassword(currentPassword: String,
                        proposedPassword: String,
                        completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.changePassword(currentPassword: currentPassword,
                                       proposedPassword: proposedPassword,
                                       completionHandler: completionHandler)
    }

    func forgotPassword(username: String,
                        clientMetaData: [String: String],
                        completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        awsMobileClient.forgotPassword(username: username,
                                       clientMetaData: clientMetaData,
                                       completionHandler: completionHandler)
    }

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               clientMetaData: [String: String],
                               completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void)) {
        awsMobileClient.confirmForgotPassword(username: username,
                                              newPassword: newPassword,
                                              confirmationCode: confirmationCode,
                                              clientMetaData: clientMetaData,
                                              completionHandler: completionHandler)
    }

    func getIdentityId() -> AWSTask<NSString> {
        return awsMobileClient.getIdentityId()
    }

    func getTokens(_ completionHandler: @escaping (Tokens?, Error?) -> Void) {
        return awsMobileClient.getTokens(completionHandler)
    }

    func getAWSCredentials(_ completionHandler: @escaping (AWSCredentials?, Error?) -> Void) {
        return awsMobileClient.getAWSCredentials(completionHandler)
    }

    func getCurrentUserState() -> UserState {
        return awsMobileClient.currentUserState
    }

    func listDevices(completionHandler: @escaping ((ListDevicesResult?, Error?) -> Void)) {
        awsMobileClient.deviceOperations.list(completionHandler: completionHandler)
    }

    func updateDeviceStatus(remembered: Bool,
                            completionHandler: @escaping ((UpdateDeviceStatusResult?, Error?) -> Void)) {
        awsMobileClient.deviceOperations.updateStatus(remembered: remembered,
                                                      completionHandler: completionHandler)
    }

    func getDevice(_ completionHandler: @escaping ((Device?, Error?) -> Void)) {
        awsMobileClient.deviceOperations.get(completionHandler)
    }

    func forgetDevice(deviceId: String, completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.deviceOperations.forget(deviceId: deviceId,
                                                completionHandler: completionHandler)
    }

    func forgetCurrentDevice(_ completionHandler: @escaping ((Error?) -> Void)) {
        awsMobileClient.deviceOperations.forget(completionHandler)
    }

    func invalidateCachedTemporaryCredentials() {
        awsMobileClient.invalidateCachedTemporaryCredentials()
    }

    func addUserStateListener(_ object: AnyObject, _ callback: @escaping UserStateChangeCallback) {
        awsMobileClient.addUserStateListener(object, callback)
    }

    func removeUserStateListener(_ object: AnyObject) {
        awsMobileClient.removeUserStateListener(object)
    }

    func releaseSignInWait() {
        awsMobileClient.releaseSignInWait()
    }
}
