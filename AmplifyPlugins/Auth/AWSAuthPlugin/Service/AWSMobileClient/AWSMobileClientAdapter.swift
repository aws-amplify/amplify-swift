//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSMobileClient

class AWSMobileClientAdapter: AWSMobileClientBehavior {

    let awsMobileClient: AWSMobileClient

    init(configuration: [String: Any]) {
        self.awsMobileClient = AWSMobileClient.init(configuration: configuration)
    }

    func initialize() throws {
        var mobileClientError: Error?
        awsMobileClient.initialize { _, error in
            mobileClientError = error
        }
        if let error = mobileClientError {
            throw AmplifyAuthError.configuration(AuthPluginErrorConstants.mobileClientInitializeError.errorDescription,
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
}
