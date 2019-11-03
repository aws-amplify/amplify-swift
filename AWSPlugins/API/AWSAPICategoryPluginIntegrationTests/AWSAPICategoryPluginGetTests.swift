//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify

class AWSAPICategoryPluginGetTests: AWSAPICategoryPluginBaseTests {

    func testSimpleGet() {
        let getCompleted = expectation(description: "get request completed")
        _ = Amplify.API.get(apiName: "none", path: "/simplesuccess") { event in
            switch event {
            case .completed(let data):
                // The endpoint echoes the request back, so we don't need to assert the whole thing
                if let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: data),
                    case .object(let response) = jsonValue,
                    case .object(let context) = response["context"],
                    case .string(let resourcePath) = context["resource-path"] {
                    XCTAssertEqual(resourcePath, "/simplesuccess")
                } else {
                    XCTFail("Could not access response object's [context][resource-path]: \(data)")
                }
                getCompleted.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    func testAPIKeyGet() {
        let getCompleted = expectation(description: "get request completed")
        _ = Amplify.API.get(apiName: "apiKey", path: "/simplesuccessapikey") { event in
            switch event {
            case .completed(let data):
                // The endpoint echoes the request back, so we don't need to assert the whole thing
                if let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: data),
                    case .object(let response) = jsonValue,
                    case .object(let context) = response["context"],
                    case .string(let resourcePath) = context["resource-path"] {
                    XCTAssertEqual(resourcePath, "/simplesuccessapikey")
                } else {
                    XCTFail("Could not access response object's [context][resource-path]: \(data)")
                }
                getCompleted.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    func testSimplePost() {
        let getCompleted = expectation(description: "post request completed")

        Amplify.API.post(apiName: "none", path: "/simplesuccess", body: "testing") { (event) in
            switch event {
            case .completed(let data):
                // The endpoint echoes the request back
                if let jsonValue = try? JSONDecoder().decode(JSONValue.self, from: data),
                    case .object(let response) = jsonValue,
                    case .object(let context) = response["context"],
                    case .string(let resourcePath) = context["resource-path"] {
                    XCTAssertEqual(resourcePath, "/simplesuccess")
                } else {
                    XCTFail("Could not access response object's [context][resource-path]: \(data)")
                }
                getCompleted.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }

        wait(for: [getCompleted], timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }


}
