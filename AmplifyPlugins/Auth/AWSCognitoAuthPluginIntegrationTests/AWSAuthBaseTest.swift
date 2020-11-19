//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSCognitoAuthPlugin

class AWSAuthBaseTest: XCTestCase {

    let networkTimeout = TimeInterval(10)
    var email = UUID().uuidString + "@" + UUID().uuidString + ".com"
    var email2 = UUID().uuidString + "@" + UUID().uuidString + ".com"

    func initializeAmplify() {
        do {
            let credentialsConfiguration = try AuthConfigurationHelper.credentialsConfiguration()
            if let emailJSONValue = credentialsConfiguration.value(at: "test_email_1"),
               case let .string(emailValue) = emailJSONValue {
                email = emailValue
            }
            if let email2JSONValue = credentialsConfiguration.value(at: "test_email_2"),
               case let .string(emailValue) = email2JSONValue {
                email2 = emailValue
            }
            let configuration = try AuthConfigurationHelper.amplifyConfiguration()
            let authPlugin = AWSCognitoAuthPlugin()
            try Amplify.add(plugin: authPlugin)
            try Amplify.configure(configuration)
            print("Amplify configured with auth plugin")
        } catch {
            print(error)
            XCTFail("Failed to initialize Amplify with \(error)")
        }
    }
}
