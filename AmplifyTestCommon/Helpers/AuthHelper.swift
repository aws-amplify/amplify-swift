//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient

class AuthHelper {
    static func initializeMobileClient() {
        let callbackInvoked = DispatchSemaphore(value: 0)

        AWSMobileClient.default().initialize { userState, error in
            if let error = error {
                if let awsMobileClientError = error as? AWSMobileClientError {
                    fatalError("Error initializing AWSMobileClient. Error: \(awsMobileClientError.message)")
                } else {
                    fatalError("Error initializing AWSMobileClient. Error: \(error.localizedDescription)")
                }
            }

            guard let userState = userState else {
                fatalError("userState is unexpectedly empty initializing AWSMobileClient")
            }

            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            print("AWSMobileClient Initialized")
            callbackInvoked.signal()
        }

        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func signUpUser(username: String, password: String) {
        let callbackInvoked = DispatchSemaphore(value: 0)
        let userAttributes = ["email": username]
        AWSMobileClient.default().signUp(username: username,
                                         password: password,
                                         userAttributes: userAttributes) { result, error in
            if let error = error {
                if let awsMobileClientError = error as? AWSMobileClientError {
                    fatalError("Failed to sign up user with error: \(awsMobileClientError.message)")
                } else {
                    fatalError("Failed to sign up user with error: \(error.localizedDescription)")
                }
            }

            guard result != nil else {
                fatalError("result from signUp should not be nil")
            }

            callbackInvoked.signal()
        }

        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func signIn(username: String, password: String) {
        let callbackInvoked = DispatchSemaphore(value: 0)

        AWSMobileClient.default().signIn(username: username, password: password) { result, error in
            if let error = error {
                if let awsMobileClientError = error as? AWSMobileClientError {
                    fatalError("Sign in failed: \(awsMobileClientError.message)")
                } else {
                    fatalError("awsMobileClientError: \(error.localizedDescription)")
                }
            }

            guard let result = result else {
                fatalError("No result from SignIn")
            }

            if result.signInState != .signedIn {
                fatalError("User is not signed in, state is \(result.signInState)")
            }
            callbackInvoked.signal()
        }
        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func signOut() {
        AWSMobileClient.default().signOut()
    }

    static func getIdentityId() -> String {
        let task = AWSMobileClient.default().getIdentityId()
        task.waitUntilFinished()
        if let error = task.error {
            fatalError("Could not get identityId, with error \(error)")
        }

        if let result = task.result {
            return result as String
        }

        fatalError("Could not get identityId from result")
    }

    static func getUserSub() -> String? {
        AWSMobileClient.default().username
    }
}
