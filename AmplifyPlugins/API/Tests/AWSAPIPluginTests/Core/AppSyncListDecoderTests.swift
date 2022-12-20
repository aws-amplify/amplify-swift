//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
import AWSPluginsCore

class AppSyncListDecoderTests: XCTestCase {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    class AppSyncListDecoderHarness<ModelType: Model>: Decodable {
        let listProvider: AppSyncListProvider<ModelType>?

        init(listProvider: AppSyncListProvider<ModelType>?) {
            self.listProvider = listProvider
        }

        required convenience init(from decoder: Decoder) throws {
            let provider = AppSyncListDecoder.shouldDecodeToAppSyncListProvider(modelType: ModelType.self, decoder: decoder)
            self.init(listProvider: provider)
        }
    }

    func testShouldDecodeFromAppSyncListPayload() throws {
        let json: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "title": JSONValue.init(stringLiteral: "title")
                ], [
                    "id": "2",
                    "title": JSONValue.init(stringLiteral: "title")
                ]
            ],
            "nextToken": "nextToken"
        ]
        let appSyncPayload = AppSyncListPayload(graphQLData: json, apiName: nil, variables: nil)
        let data = try encoder.encode(appSyncPayload)

        let harness = try decoder.decode(AppSyncListDecoderHarness<Post4>.self, from: data)
        XCTAssertNotNil(harness.listProvider)
        guard let provider = harness.listProvider else {
            XCTFail("Could get AppSyncListProvider")
            return
        }
        guard case .loaded(let elements, let nextToken, let filter) = provider.loadedState else {
            XCTFail("Should be in loaded state")
            return
        }
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        XCTAssertNil(filter)
    }

    func testShouldNotDecodeForInvalidAppSyncListPayload() throws {
        let json: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "invalidKeyForPost4": JSONValue.init(stringLiteral: "title")
                ]
            ],
            "nextToken": "nextToken"
        ]
        let appSyncPayload = AppSyncListPayload(graphQLData: json, apiName: nil, variables: nil)
        let data = try encoder.encode(appSyncPayload)
        let result = try decoder.decode(AppSyncListDecoderHarness<Post4>.self, from: data)
        XCTAssertNil(result.listProvider)
    }

    func testShouldDecodeFromModelMetadata() throws {
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedField: "post",
                                                        apiName: "apiName")
        let data = try encoder.encode(modelMetadata)
        let harness = try decoder.decode(AppSyncListDecoderHarness<Comment4>.self, from: data)
        XCTAssertNotNil(harness.listProvider)
        guard let provider = harness.listProvider else {
            XCTFail("Could get AppSyncListProvider")
            return
        }
        guard case .notLoaded(let associatedIdentifiers, let associatedField) = provider.getState() else {
            XCTFail("Should be in not loaded state")
            return
        }
        XCTAssertEqual(associatedIdentifiers, ["postId"])
        XCTAssertEqual(associatedField, "post")
    }

    func testShouldDecodeFromAWSAppSyncListResponse() throws {
        let listResponse = AppSyncListResponse<Post4>(items: [Post4(title: "title"),
                                                                 Post4(title: "title")],
                                                                nextToken: "nextToken")
        let data = try encoder.encode(listResponse)
        let harness = try decoder.decode(AppSyncListDecoderHarness<Post4>.self, from: data)
        XCTAssertNotNil(harness.listProvider)
        guard let provider = harness.listProvider else {
            XCTFail("Could get AppSyncListProvider")
            return
        }
        guard case .loaded(let elements, let nextToken, let filter) = provider.loadedState else {
            XCTFail("Should be in loaded state")
            return
        }
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        XCTAssertNil(filter)
    }

    func testInvalidPayload() throws {
        let json = "json"
        let data = try encoder.encode(json)
        let result = try self.decoder.decode(AppSyncListDecoderHarness<Comment4>.self, from: data)
        XCTAssertNil(result.listProvider)
        
    }
}
