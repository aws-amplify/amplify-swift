//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class AuthHelper {

    static func signUpUser(username: String, password: String) {
        let callbackInvoked = DispatchSemaphore(value: 0)
        let userAttributes = [AuthUserAttribute(.email, value: username)]
        let options = AuthSignUpRequest.Options(userAttributes: userAttributes,
                                                pluginOptions: nil)
        _ = Amplify.Auth.signUp(username: username,
                                password: password,
                                options: options) { event in
                                    defer {
                                        callbackInvoked.signal()
                                    }
                                    switch event {
                                    case .completed(let result):
                                        print(result)
                                    case .failed(let error):
                                        fatalError("Failed to sign up user with error: \(error)")
                                    default:
                                        fatalError("Wrong event result returned Auth.signUp")
                                    }
        }
        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func signIn(username: String, password: String) {
        let callbackInvoked = DispatchSemaphore(value: 0)

        _ = Amplify.Auth.signIn(username: username,
                                password: password) { event in
                                    defer {
                                        callbackInvoked.signal()
                                    }
                                    switch event {
                                    case .completed(let result):
                                        print(result)
                                    case .failed(let error):
                                        fatalError("Failed to sign in user with error: \(error)")
                                    default:
                                        fatalError("Wrong event result returned for Auth.signIn ")
                                    }
        }
        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func signOut() {
        let callbackInvoked = DispatchSemaphore(value: 0)
        _ = Amplify.Auth.signOut { _ in
            callbackInvoked.signal()
        }
        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
    }

    static func getIdentityId() -> String {

        let callbackInvoked = DispatchSemaphore(value: 0)
        var result: Result<String, AuthError>?

        _ = Amplify.Auth.fetchAuthSession { event in
            defer {
                callbackInvoked.signal()
            }

            switch event {
            case .completed(let session):
                result = (session as? AuthCognitoIdentityProvider)?.getIdentityId()
            case .failed(let error):
                result = .failure(error)
            default: break

            }
        }
        _ = callbackInvoked.wait(timeout: .now() + TestCommonConstants.networkTimeout)
        guard let validResult = try? result?.get() else {
            fatalError("Wrong event result returned for Auth.fetchAuthSession")
        }
        return validResult
    }
}
