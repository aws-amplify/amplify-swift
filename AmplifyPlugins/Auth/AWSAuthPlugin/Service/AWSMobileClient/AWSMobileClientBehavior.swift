//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient

protocol AWSMobileClientBehavior {

    func initialize() throws

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
                          completionHandler: @escaping ((SignUpResult?, Error?) -> Void))

    func signIn(username: String,
                password: String,
                validationData: [String: String]?,
                completionHandler: @escaping ((SignInResult?, Error?) -> Void))

    func federatedSignIn(providerName: String, token: String,
                         federatedSignInOptions: FederatedSignInOptions,
                         completionHandler: @escaping ((UserState?, Error?) -> Void))

    func showSignIn(navigationController: UINavigationController,
                    signInUIOptions: SignInUIOptions,
                    hostedUIOptions: HostedUIOptions?,
                    _ completionHandler: @escaping (UserState?, Error?) -> Void)

    func confirmSignIn(challengeResponse: String,
                       userAttributes: [String: String],
                       clientMetaData: [String: String],
                       completionHandler: @escaping ((SignInResult?, Error?) -> Void))

    func signOut(options: SignOutOptions,
                 completionHandler: @escaping ((Error?) -> Void))

    func username() -> String?

    func verifyUserAttribute(attributeName: String,
                             completionHandler: @escaping ((UserCodeDeliveryDetails?, Error?) -> Void))

    func updateUserAttributes(attributeMap: [String: String],
                              completionHandler: @escaping (([UserCodeDeliveryDetails]?, Error?) -> Void))

    func getUserAttributes(completionHandler: @escaping (([String: String]?, Error?) -> Void))

    func confirmUpdateUserAttributes(attributeName: String, code: String,
                                     completionHandler: @escaping ((Error?) -> Void))

    func changePassword(currentPassword: String,
                        proposedPassword: String,
                        completionHandler: @escaping ((Error?) -> Void))
}
