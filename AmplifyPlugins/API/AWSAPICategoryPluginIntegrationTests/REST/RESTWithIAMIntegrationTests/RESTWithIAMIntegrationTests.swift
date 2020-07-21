//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAPICategoryPlugin
import AWSMobileClient
@testable import AmplifyTestCommon

class RESTWithIAMIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "RESTWithIAMIntegrationTests-amplifyconfiguration"
    static let awsconfiguration = "RESTWithIAMIntegrationTests-awsconfiguration"

    override func setUp() {

        do {
            let awsConfiguration = try TestConfigHelper.retrieveAWSConfiguration(
                forResource: RESTWithIAMIntegrationTests.awsconfiguration)
            AWSInfo.configureDefaultAWSInfo(awsConfiguration)

            AuthHelper.initializeMobileClient()

            Amplify.reset()

            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: RESTWithIAMIntegrationTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testGetAPISuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .success(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetAPIFailedAccessDenied() {
        let failedInvoked = expectation(description: "request failed")
        let request = RESTRequest(path: "/invalidPath")
        _ = Amplify.API.get(request: request) { event in
            switch event {
            case .success(let data):
                XCTFail("Unexpected .complted event: \(data)")
            case .failure(let error):
                guard case let .httpStatusError(statusCode, _, _) = error else {
                    XCTFail("Error should be httpStatusError")
                    return
                }

                XCTAssertEqual(statusCode, 403)
                failedInvoked.fulfill()
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testPutAPISuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.put(request: request) { event in
            switch event {
            case .success(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testPostAPISuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.post(request: request) { event in
            switch event {
            case .success(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAPISuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.delete(request: request) { event in
            switch event {
            case .success(let data):
                let result = String(decoding: data, as: UTF8.self)
                print(result)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testHeadAPIAccessDenied() {
        let failedInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.head(request: request) { event in
            switch event {
            case .success(let data):
                XCTFail("Unexpected .completed event: \(data)")
            case .failure(let error):
                guard case let .httpStatusError(statusCode, _, _) = error else {
                    XCTFail("Error should be httpStatusError")
                    return
                }

                XCTAssertEqual(statusCode, 403)
                failedInvoked.fulfill()
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testPatchAPINotFound() {
        let failedInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items")
        _ = Amplify.API.patch(request: request) { event in
            switch event {
            case .success(let data):
                XCTFail("Unexpected .completed event: \(data)")
            case .failure(let error):
                guard case let .httpStatusError(statusCode, _, _) = error else {
                    XCTFail("Error should be httpStatusError")
                    return
                }

                XCTAssertEqual(statusCode, 404)
                failedInvoked.fulfill()
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

}
