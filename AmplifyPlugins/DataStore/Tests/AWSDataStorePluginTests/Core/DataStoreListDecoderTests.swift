//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
@testable import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class DataStoreListDecoderTests: BaseDataStoreTests {

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    class DataStoreListDecoderHarness<ModelType: Model>: Decodable {
        var shouldDecode = false
        let listProvider: DataStoreListProvider<ModelType>?

        init(shouldDecode: Bool, listProvider: DataStoreListProvider<ModelType>?) {
            self.shouldDecode = shouldDecode
            self.listProvider = listProvider
        }

        required convenience init(from decoder: Decoder) throws {
            let shouldDecode = DataStoreListDecoder.shouldDecode(modelType: ModelType.self, decoder: decoder)
            let provider = try DataStoreListDecoder.getDataStoreListProvider(modelType: ModelType.self,
                                                                             decoder: decoder)
            self.init(shouldDecode: shouldDecode, listProvider: provider)
        }
    }

    func testDataStoreListDecoderShouldDecodeFromArrayJSON() throws {
        let json: JSONValue = [
            [
                "id": "1",
                "title": JSONValue.init(stringLiteral: "title")
            ], [
                "id": "2",
                "title": JSONValue.init(stringLiteral: "title")
            ]
        ]
        let data = try encoder.encode(json)
        let harness = try decoder.decode(DataStoreListDecoderHarness<Post4>.self, from: data)
        XCTAssertTrue(harness.shouldDecode)
        XCTAssertNotNil(harness.listProvider)
        guard let provider = harness.listProvider else {
            XCTFail("Could get AppSyncListProvider")
            return
        }
        guard case .loaded(let elements) = provider.loadedState else {
            XCTFail("Should be in loaded state")
            return
        }
        XCTAssertEqual(elements.count, 2)
    }

    func testDataStoreListDecoderShouldDecodeFromAssociationData() throws {
        let json: JSONValue = [
            "associatedId": "postId",
            "associatedField": "post"
        ]
        let data = try encoder.encode(json)
        let harness = try decoder.decode(DataStoreListDecoderHarness<Post4>.self, from: data)
        XCTAssertTrue(harness.shouldDecode)
        XCTAssertNotNil(harness.listProvider)
        guard let provider = harness.listProvider else {
            XCTFail("Could get AppSyncListProvider")
            return
        }
        guard case .notLoaded(let associatedId, let associatedField) = provider.loadedState else {
            XCTFail("Should be in loaded state")
            return
        }
        XCTAssertEqual(associatedId, "postId")
        XCTAssertEqual(associatedField, "post")
    }

    func testDataStoreListDecoderAssertForInvalidAssociationData() throws {
        let json: JSONValue = [
            "associatedId": "postId",
            "associatedField": ["invalidField"]
        ]
        let data = try encoder.encode(json)
        try XCTAssertThrowFatalError {
            _ = try? self.decoder.decode(DataStoreListDecoderHarness<Post4>.self, from: data)
        }
    }

    func testDataStoreListDecoderShouldNotDecodeFromMissingAssociationData() throws {
        let json: JSONValue = [
            "associatedId": "123"
        ]
        let data = try encoder.encode(json)
        try XCTAssertThrowFatalError {
            _ = try? self.decoder.decode(DataStoreListDecoderHarness<Post4>.self, from: data)
        }
    }

    func testDataStoreListDecoderShouldNotDecodeJSONString() throws {
        let json: JSONValue = "JSONString"
        let data = try encoder.encode(json)
        try XCTAssertThrowFatalError {
            _ = try? self.decoder.decode(DataStoreListDecoderHarness<Post4>.self, from: data)
        }
    }
}
