//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

class AppSyncListDecoderTests: XCTestCase {

    func testAppSyncListDecoderShouldDecodeFromItemsObjectJSON() throws {
        let json: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "title": JSONValue.init(stringLiteral: "title")
                ], [
                    "id": "2",
                    "title": JSONValue.init(stringLiteral: "title")
                ]
            ]
        ]
        XCTAssertTrue(AppSyncListDecoder.shouldDecode(json: json))
        let data = try AppSyncListDecoderTests.encode(json: json)
        let list = try AppSyncListDecoderTests.decodeToList(data, responseType: Post4.self)
        XCTAssertNotNil(list)
    }

    func testDataStoreListDecoderShouldNotDecodeFromMissingArray() throws {
        let json: JSONValue = [
            "items": "shouldBeArray"
        ]
        XCTAssertFalse(AppSyncListDecoder.shouldDecode(json: json))
        let data = try AppSyncListDecoderTests.encode(json: json)
        let list = try AppSyncListDecoderTests.decodeToList(data, responseType: Comment4.self)
        XCTAssertEqual(list.count, 0)
    }

    func testDataStoreListDecoderShouldNotDecodeFromInvalidJSONObject() throws {
        let json: JSONValue = "invalidJSONObject"
        XCTAssertFalse(AppSyncListDecoder.shouldDecode(json: json))
        let data = try AppSyncListDecoderTests.encode(json: json)
        let list = try AppSyncListDecoderTests.decodeToList(data, responseType: Comment4.self)
        XCTAssertEqual(list.count, 0)
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
