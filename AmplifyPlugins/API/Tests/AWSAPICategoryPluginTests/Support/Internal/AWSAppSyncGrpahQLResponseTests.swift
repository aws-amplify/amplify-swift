//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AWSAPIPlugin

class AWSAppSyncGrpahQLResponseTests: XCTestCase {

    static let decoder = JSONDecoder()
    static let encoder = JSONEncoder()

    override class func setUp() {
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
    }

    func testDecodeToDataResponse() throws {
        let graphQLResponse: [String: JSONValue] = [
            "data": [
                "some": "value"
            ]
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case let .data(graphQLData) = result else {
            XCTFail("Could not get correct response")
            return
        }

        guard let firstObject = graphQLData.first else {
            XCTFail("Could not get first data object")
            return
        }

        XCTAssertEqual(firstObject.key, "some")
        XCTAssertEqual(firstObject.value, "value")
    }

    func testDecodeToErrorsResponse() throws {
        let graphQLResponse: [String: JSONValue] = [
            "errors": [
                "error1",
                "error2"
            ]
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case let .errors(graphQLErrors) = result else {
            XCTFail("Could not get correct response")
            return
        }

        XCTAssertEqual(graphQLErrors.count, 2)
        XCTAssertEqual(graphQLErrors[0], "error1")
        XCTAssertEqual(graphQLErrors[1], "error2")
    }

    func testDecodeToPartialResponse() throws {
        let graphQLResponse: [String: JSONValue] = [
            "data": [
                "some": "value"
            ],
            "errors": [
                "error1",
                "error2"
            ]
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case let .partial(graphQLData, graphQLErrors) = result else {
            XCTFail("Could not get correct response")
            return
        }
        guard let firstObject = graphQLData.first else {
            XCTFail("Could not get first data object")
            return
        }

        XCTAssertEqual(firstObject.key, "some")
        XCTAssertEqual(firstObject.value, "value")
        XCTAssertEqual(graphQLErrors.count, 2)
        XCTAssertEqual(graphQLErrors[0], "error1")
        XCTAssertEqual(graphQLErrors[1], "error2")
    }

    func testDecodeWithMissingKeysToInvalidResponse() throws {
        let graphQLResponse: [String: String] = [
            "missingData": "response",
            "missingErrors": "response"
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case .invalidResponse = result else {
            XCTFail("Could not get correct response")
            return
        }
    }

    func testDecodeWithInvalidDataToInvalidResponse() throws {
        let graphQLResponse: [String: JSONValue] = [
            "data": [
                "array1",
                "array2"
            ],
            "errors": [
                "error1",
                "error2"
            ]
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case .invalidResponse = result else {
            XCTFail("Could not get correct response")
            return
        }
    }

    func testDecodeWithInvalidErrorsToInvalidResponse() throws {
        let graphQLResponse: [String: JSONValue] = [
            "data": [
                "some": "value"
            ],
            "errors": [
                "dictKey": "dictValue"
            ]
        ]

        let responseData = try AWSAppSyncGrpahQLResponseTests.encoder.encode(graphQLResponse)

        let result = try AWSAppSyncGraphQLResponse.decodeToAWSAppSyncGraphQLResponse(response: responseData)

        guard case .invalidResponse = result else {
            XCTFail("Could not get correct response")
            return
        }
    }
}
