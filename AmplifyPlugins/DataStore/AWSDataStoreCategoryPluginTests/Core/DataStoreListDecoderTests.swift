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
@testable import AWSDataStoreCategoryPlugin
import CwlPreconditionTesting

class DataStoreListDecoderTests: BaseDataStoreTests {

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
        XCTAssertTrue(DataStoreListDecoder.shouldDecode(json: json))
        let data = try DataStoreListDecoderTests.encode(json: json)
        let list = try DataStoreListDecoderTests.decodeToList(data, responseType: Post4.self)
        XCTAssertNotNil(list)
    }

    func testDataStoreListDecoderShouldDecodeFromAssociationData() throws {
        let json: JSONValue = [
            "associatedId": "postId",
            "associatedField": "post"
        ]
        XCTAssertTrue(DataStoreListDecoder.shouldDecode(json: json))
        let data = try DataStoreListDecoderTests.encode(json: json)
        let list = try DataStoreListDecoderTests.decodeToList(data, responseType: Comment4.self)
        XCTAssertNotNil(list)
    }

    func testDataStoreListDecoderAssertForMissingAssociationField() throws {
        let json: JSONValue = [
            "associatedId": "postId",
            "associatedField": "invalidField"
        ]
        XCTAssertTrue(DataStoreListDecoder.shouldDecode(json: json))
        let data = try DataStoreListDecoderTests.encode(json: json)
        let caughtAssert = catchBadInstruction {
            _ = try? DataStoreListDecoderTests.decodeToList(data, responseType: Comment4.self)
        }
        XCTAssertNotNil(caughtAssert)
    }

    func testDataStoreListDecoderShouldNotDecodeFromMissingAssociationData() throws {
        let json: JSONValue = [
            "associatedId": "123"
        ]
        XCTAssertFalse(DataStoreListDecoder.shouldDecode(json: json))
        let data = try DataStoreListDecoderTests.encode(json: json)
        let list = try DataStoreListDecoderTests.decodeToList(data, responseType: Comment4.self)
        XCTAssertNotNil(list)
    }

    func testDataStoreListDecoderShouldNotDecodeJSONString() throws {
        let json: JSONValue = "JSONString"
        XCTAssertFalse(DataStoreListDecoder.shouldDecode(json: json))
        let data = try DataStoreListDecoderTests.encode(json: json)
        let list = try DataStoreListDecoderTests.decodeToList(data, responseType: Comment4.self)
        XCTAssertNotNil(list)
    }

    // MARK: - Helpers

    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        return try encoder.encode(json)
    }

    private static func decodeToList<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }
}
