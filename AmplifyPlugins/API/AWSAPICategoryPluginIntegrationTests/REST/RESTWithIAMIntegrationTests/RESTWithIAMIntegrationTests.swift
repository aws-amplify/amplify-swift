//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class RESTWithIAMIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "RESTWithIAMIntegrationTests-amplifyconfiguration"

    override func setUp() {

        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
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

    func testSetUp() {
        XCTAssertTrue(true)
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
                if case let .httpStatusError(_, response) = error,
                    let awsResponse = response as? AWSHTTPURLResponse,
                    let responseBody = awsResponse.body {
                    let str = String(decoding: responseBody, as: UTF8.self)

                    print("Response contains a \(str)")
                }
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
                guard case let .httpStatusError(statusCode, response) = error else {
                    XCTFail("Error should be httpStatusError")
                    return
                }
                XCTAssertNotNil(response.url)
                XCTAssertEqual(response.mimeType, "application/json")
                // XCTAssertEqual(response.expectedContentLength, 272)
                XCTAssertEqual(response.statusCode, 403)
                XCTAssertNotNil(response.allHeaderFields)
                if let awsResponse = response as? AWSHTTPURLResponse, let data = awsResponse.body {
                    let dataString = String(decoding: data, as: UTF8.self)
                    XCTAssertTrue(dataString.contains("not authorized"))
                } else {
                    XCTFail("Missing response body")
                }
                XCTAssertEqual(statusCode, 403)
                failedInvoked.fulfill()
            }
        }

        wait(for: [failedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testGetAPIWithQueryParamsSuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello@email.com",
                                    "created": "2021-06-18T09:00:00Z"
                                  ])
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

    func testGetAPIWithEncodedQueryParamsSuccess() {
        let completeInvoked = expectation(description: "request completed")
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello%40email.com",
                                    "created": "2021-06-18T09%3A00%3A00Z"
                                  ])
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
                guard case let .httpStatusError(statusCode, _) = error else {
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
                guard case let .httpStatusError(statusCode, _) = error else {
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
