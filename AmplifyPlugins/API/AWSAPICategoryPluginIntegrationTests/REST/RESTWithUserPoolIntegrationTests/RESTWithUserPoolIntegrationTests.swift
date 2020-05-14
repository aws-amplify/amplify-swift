//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAPICategoryPlugin
@testable import AmplifyTestCommon

class RESTWithUserPoolIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "RESTWithUserPoolIntegrationTests-amplifyconfiguration"
    static let awsconfiguration = "RESTWithUserPoolIntegrationTests-awsconfiguration"
    static let credentials = "RESTWithUserPoolIntegrationTests-credentials"
    static var user1: String!
    static var password: String!

    static override func setUp() {
        do {

            let credentials = try TestConfigHelper.retrieveCredentials(
                forResource: RESTWithUserPoolIntegrationTests.credentials)

            guard let user1 = credentials["user1"], let password = credentials["password"] else {
                XCTFail("Missing credentials.json data")
                return
            }

            RESTWithUserPoolIntegrationTests.user1 = user1
            RESTWithUserPoolIntegrationTests.password = password

            let awsConfiguration = try TestConfigHelper.retrieveAWSConfiguration(
                forResource: RESTWithUserPoolIntegrationTests.awsconfiguration)
            AWSInfo.configureDefaultAWSInfo(awsConfiguration)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func setUp() {
        do {
            AuthHelper.initializeMobileClient()

            Amplify.reset()

            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: RESTWithUserPoolIntegrationTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testGetAPISuccess() {
        AuthHelper.signIn(username: RESTWithUserPoolIntegrationTests.user1,
                          password: RESTWithUserPoolIntegrationTests.password)
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .completed(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetAPIFailedWithNotAuthenticated() {
        AuthHelper.signOut()
        let failedInvoked = expectation(description: "request failed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .completed(let data):
                XCTFail("Unexpected .complted event: \(data)")
            case .failed(let error):
                guard case let .operationError(_, _, underlyingError) = error else {
                    XCTFail("Error should be operationError")
                    return
                }

                guard let authError = underlyingError as? AuthError else {
                    XCTFail("underlying error should be AuthError, but instead was \(underlyingError ?? "nil")")
                    return
                }

                guard case .notAuthenticated = authError else {
                    XCTFail("Error should be AuthError.notAuthenticated")
                    return
                }

                failedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }
}
