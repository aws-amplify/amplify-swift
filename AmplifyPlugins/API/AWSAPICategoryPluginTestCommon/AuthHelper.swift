//
// Copyright 2018-2019 Amazon.com,
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
                fatalError("Error initializing AWSMobileClient. Error: \(error.localizedDescription)")
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
        AWSMobileClient.default().signUp(username: username, password: password, userAttributes: userAttributes) { result, error in

            if let error = error as? AWSMobileClientError {
                fatalError("Failed to sign up user with error: \(error.message)")
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
                fatalError("Sign in failed: \(error.localizedDescription)")
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
}
