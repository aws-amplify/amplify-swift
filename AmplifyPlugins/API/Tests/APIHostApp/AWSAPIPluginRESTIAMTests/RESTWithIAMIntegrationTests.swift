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
#if os(watchOS)
@testable import APIWatchApp
#else
@testable import APIHostApp
#endif

class RESTWithIAMIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "testconfiguration/RESTWithIAMIntegrationTests-amplifyconfiguration"
    
    override func setUp() async throws {

        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                            forResource: RESTWithIAMIntegrationTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testSetUp() {
        XCTAssertTrue(true)
    }

    func testGetAPISuccess() async throws {
        let request = RESTRequest(path: "/items")
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testGetAPIFailedAccessDenied() async {
        let request = RESTRequest(path: "/invalidPath")
        do {
            _ = try await Amplify.API.get(request: request)
        } catch {
            guard let apiError = error as? APIError else {
                XCTFail("Error should be APIError")
                return
            }
            
            guard case let .httpStatusError(statusCode, response) = apiError else {
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
        }
    }

    // TODO: Should not be HTTPStatusError
    func testGetAPIWithQueryParamsSuccess() async throws {
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello@email.com",
                                    "created": "2021-06-18T09:00:00Z"
                                  ])
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testGetAPIWithEncodedQueryParamsSuccess() async throws {
        let request = RESTRequest(path: "/items",
                                  queryParameters: [
                                    "user": "hello%40email.com",
                                    "created": "2021-06-18T09%3A00%3A00Z"
                                  ])
        let data = try await Amplify.API.get(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testPutAPISuccess() async throws {
        let request = RESTRequest(path: "/items")
        let data = try await Amplify.API.put(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testPostAPISuccess() async throws {
        let request = RESTRequest(path: "/items")
        let data = try await Amplify.API.post(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testDeleteAPISuccess() async throws {
        let request = RESTRequest(path: "/items")
        let data = try await Amplify.API.delete(request: request)
        let result = String(decoding: data, as: UTF8.self)
        log.info(result)
    }

    func testHeadAPIAccessDenied() async throws {
        let request = RESTRequest(path: "/items")
        do {
            _ = try await Amplify.API.head(request: request)
            XCTFail("Should catch error")
        } catch {
            guard let apiError = error as? APIError else {
                XCTFail("Error should be APIError")
                return
            }
            guard case let .httpStatusError(statusCode, _) = apiError else {
                XCTFail("Error should be httpStatusError")
                return
            }
            
            XCTAssertEqual(statusCode, 403)
        }
    }

    func testPatchAPINotFound() async throws {
        let request = RESTRequest(path: "/items")
        do {
            _ = try await Amplify.API.patch(request: request)
            XCTFail("Should catch error")
        } catch {
            guard let apiError = error as? APIError else {
                XCTFail("Error should be APIError")
                return
            }
            guard case let .httpStatusError(statusCode, _) = apiError else {
                XCTFail("Error should be httpStatusError")
                return
            }
            
            XCTAssertEqual(statusCode, 404)
        }
    }

    func testRestRequest_withCustomizeHeaders_succefullyOverride() async throws {
        let request = RESTRequest(path: "/items", headers: ["Content-Type": "text/plain"])
        do {
            _ = try await Amplify.API.get(request: request)
        } catch {
            guard let apiError = error as? APIError else {
                XCTFail("Error should be APIError")
                return
            }
            guard case let .httpStatusError(statusCode, _) = apiError else {
                XCTFail("Error should be httpStatusError")
                return
            }

            XCTAssertEqual(statusCode, 403)
        }
    }
}

extension RESTWithIAMIntegrationTests: DefaultLogger { }
