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
@testable import AWSAPICategoryPluginTestCommon

class AWSAPICategoryPluginGetTests: XCTestCase {

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPICategoryPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "none": [
                    "endpoint": "https://0idx6yjn11.execute-api.us-east-1.amazonaws.com/beta",
                    "region": "us-east-1",
                    "authorizationType": "NONE",
                    "endpointType": "REST"
                ],
                "apiKey": [
                    "endpoint": "https://rqdxvfh3ue.execute-api.us-east-1.amazonaws.com/Prod",
                    "region": "us-east-1",
                    "authorizationType": "API_KEY",
                    "apiKey": "KjbPeqbh9F7hc2n2UVkpfD8WKF1kkYX3ydrkyHq6",
                    "endpointType": "REST"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testSimpleGet() {
        let getCompleted = expectation(description: "get request completed")
        let request = RESTRequest(apiName: "none",
                                  path: "/simplesuccess")
        _ = Amplify.API.get(request: request) { event in
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

        wait(for: [getCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testAPIKeyGet() {
        let getCompleted = expectation(description: "get request completed")
        let request = RESTRequest(apiName: "apiKey",
                                  path: "/simplesuccessapikey")
        _ = Amplify.API.get(request: request) { event in
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

        wait(for: [getCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testSimplePost() {
        let getCompleted = expectation(description: "post request completed")
        let request = RESTRequest(apiName: "none",
                                  path: "/simplesuccess",
                                  body: Data())
        Amplify.API.post(request: request) { event in
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

        wait(for: [getCompleted], timeout: TestCommonConstants.networkTimeout)
    }
}
