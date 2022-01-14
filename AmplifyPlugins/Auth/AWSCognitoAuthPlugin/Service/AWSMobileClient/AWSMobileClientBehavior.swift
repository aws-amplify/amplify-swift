//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

protocol AWSMobileClientBehavior {

    func initialize() throws

    // swiftlint:disable:next function_parameter_count
    func signUp(username: String,
                password: String,
                userAttributes: [String: String],
                validationData: [String: String],
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignUpResult?, Error?) -> Void))

    func confirmSignUp(username: String,
                       confirmationCode: String,
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignUpResult?, Error?) -> Void))

    func resendSignUpCode(username: String,
                          clientMetaData: [String: String],
                          completionHandler: @escaping ((SignUpResult?, Error?) -> Void))

    func signIn(username: String,
                password: String,
                validationData: [String: String]?,
                clientMetaData: [String: String],
                completionHandler: @escaping ((SignInResult?, Error?) -> Void))

    func federatedSignIn(providerName: String, token: String,
                         federatedSignInOptions: FederatedSignInOptions,
                         completionHandler: @escaping ((UserState?, Error?) -> Void))

    func showSignIn(navigationController: UINavigationController,
                    signInUIOptions: SignInUIOptions,
                    hostedUIOptions: HostedUIOptions?,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void)

    @available(iOS 13, *)
    func showSignIn(uiwindow: UIWindow,
                    hostedUIOptions: HostedUIOptions,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void)

    func confirmSignIn(challengeResponse: String,
                       userAttributes: [String: String],
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignInResult?, Error?) -> Void))

    func signOut(options: SignOutOptions,
                 completionHandler: @escaping ((Error?) -> Void))

    @available(iOS 13, *)
    func signOut(uiwindow: UIWindow,
                 options: SignOutOptions,
                 completionHandler: @escaping ((Error?) -> Void))

    func signOutLocally()

    func deleteUser(completionHandler: @escaping ((Error?) -> Void))

    func getUsername() -> String?

    func getUserSub() -> String?

    func verifyUserAttribute(attributeName: String,
                             clientMetaData: [String: String],
                             completionHandler: @escaping ((UserCodeDeliveryDetails?, Error?) -> Void))

    func updateUserAttributes(attributeMap: [String: String],
                              clientMetaData: [String: String],
                              completionHandler: @escaping (([UserCodeDeliveryDetails]?, Error?) -> Void))

    func getUserAttributes(completionHandler: @escaping (([String: String]?, Error?) -> Void))

    func confirmUpdateUserAttributes(attributeName: String, code: String,
                                     completionHandler: @escaping ((Error?) -> Void))

    func changePassword(currentPassword: String,
                        proposedPassword: String,
                        completionHandler: @escaping ((Error?) -> Void))

    func forgotPassword(username: String,
                        clientMetaData: [String: String],
                        completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void))

    func confirmForgotPassword(username: String,
                               newPassword: String,
                               confirmationCode: String,
                               clientMetaData: [String: String],
                               completionHandler: @escaping ((ForgotPasswordResult?, Error?) -> Void))

    func getIdentityId() -> AWSTask<NSString>

    func getTokens(_ completionHandler: @escaping (Tokens?, Error?) -> Void)

    func getAWSCredentials(_ completionHandler: @escaping (AWSCredentials?, Error?) -> Void)

    func getCurrentUserState() -> UserState

    func listDevices(completionHandler: @escaping ((ListDevicesResult?, Error?) -> Void))

    func updateDeviceStatus(remembered: Bool,
                            completionHandler: @escaping ((UpdateDeviceStatusResult?, Error?) -> Void))

    func getDevice(_ completionHandler: @escaping ((Device?, Error?) -> Void))

    func forgetDevice(deviceId: String, completionHandler: @escaping ((Error?) -> Void))

    func forgetCurrentDevice(_ completionHandler: @escaping ((Error?) -> Void))

    func invalidateCachedTemporaryCredentials()

    func addUserStateListener(_ object: AnyObject, _ callback: @escaping UserStateChangeCallback)

    func removeUserStateListener(_ object: AnyObject)

    func releaseSignInWait()
}
