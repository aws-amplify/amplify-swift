//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPredictionsPlugin

final class EventStreamCoderTestCase: XCTestCase {
    struct Model: Codable, Equatable {
        let foo: Int
        let bar: String
        let baz: Baz

        struct Baz: Codable, Equatable {
            let quux: Bool
        }
    }

    /// Given: A payload and headers.
    /// When: Encoding the payload and headers using `EventStream.Encoder().encode(payload:headers:)`
    /// Then: The returned data should be conformant to the EventStream spec.
    func testBasicModelWithStringHeader() throws {
        let model = Model(foo: 42, bar: "hello, world!", baz: .init(quux: true))

        let headers: [String: EventStream.HeaderValue] = [
            "string_ex": .string("abc")
        ]

        let data = try JSONEncoder().encode(model)
        let encoded = EventStream.Encoder().encode(payload: data, headers: headers)
        let encodedBytes = [UInt8](encoded)

        let expectedBytes: [UInt8] = [
            // Total Byte Length
            // 84 bytes
            0, 0, 0, 84,

            // Headers Byte Length
            // 16 bytes
            0, 0, 0, 16,

            // Prelude CRC
            181, 6, 166, 6,

            // Headers
            // Headers - Header Name Byte Length
            9,
            // Headers - Header Name
            // "string_ex"
            115, 116, 114, 105, 110, 103, 95, 101, 120,
            // Headers - Header Value Type
            // 7 == String
            7,
            // Headers - Value String Byte Length
            // 3 bytes
            0, 3,
            // Headers - Value String
            // "abc"
            97, 98, 99,

            // Payload
            123, 34, 102, 111, 111, 34, 58, 52, 50, 44, 34,
            98, 97, 114, 34, 58, 34, 104, 101, 108, 108, 111,
            44, 32, 119, 111, 114, 108, 100, 33, 34, 44, 34,
            98, 97, 122, 34, 58, 123, 34, 113, 117, 117, 120,
            34, 58, 116, 114, 117, 101, 125, 125,

            // Message CRC
            55, 84, 52, 84
         ]

        XCTAssertEqual(encodedBytes, expectedBytes)
    }


    /// Given: A payload and headers
    /// When: Encoding the payload and headers to data, then decoding that data.
    /// Then: The payload and headers of the decoded data should equal that of the payload
    /// and headers before they were initially encoded.
    func testEncodingThenDecoding() throws {
        let model = Model(foo: 42, bar: "hello, world!", baz: .init(quux: true))

        let _header = (key: "string_ex", value: "abc")
        let headers: [String: EventStream.HeaderValue] = [
            _header.key: .string(_header.value)
        ]

        let data = try JSONEncoder().encode(model)
        let encoded = EventStream.Encoder().encode(payload: data, headers: headers)

        let decoded = try EventStream.Decoder().decode(data: encoded)
        let decodedModel = try JSONDecoder().decode(Model.self, from: decoded.payload)
        XCTAssertEqual(model, decodedModel)

        let decodedHeader = try XCTUnwrap(decoded.headers.first)
        XCTAssertEqual(decodedHeader.name, _header.key)
        XCTAssertEqual(decodedHeader.value, _header.value)
    }
}
