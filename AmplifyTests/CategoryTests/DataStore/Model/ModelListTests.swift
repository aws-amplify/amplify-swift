//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify

class ModelListTests: XCTestCase {

    override func setUp() {
        ModelListDecoderRegistry.reset()
    }

    struct BasicModel: Model {
        var id: Identifier
    }

    class BasicListDecoder: ModelListDecoder {
        static func shouldDecode(decoder: Decoder) -> Bool {
            let json = try? JSONValue(from: decoder)
            if case .array = json {
                return true
            }

            return false
        }

        static func decode<ModelType>(decoder: Decoder,
                                      modelType: ModelType.Type) throws -> List<ModelType> where ModelType: Model {
            try BasicList<ModelType>.init(from: decoder)
        }
    }

    class BasicList<ModelType: Model>: List<ModelType> {

        var storedElements: [Element]

        public override var elements: Elements {
            storedElements
        }

        // MARK: - Initializers

        init(_ elements: Elements) {
            self.storedElements = elements
        }

        // MARK: - ExpressibleByArrayLiteral

        required convenience public init(arrayLiteral elements: Element...) {
            self.init(elements)
        }

        // MARK: - Collection conformance

        public override var startIndex: Index {
            return elements.startIndex
        }

        public override var endIndex: Index {
            return elements.endIndex
        }

        public override func index(after index: Index) -> Index {
            return elements.index(after: index)
        }

        public override subscript(position: Int) -> Element {
            return elements[position]
        }

        override public __consuming func makeIterator() -> IndexingIterator<Elements> {
            return elements.makeIterator()
        }

        // MARK: - Codable

        required convenience init(from decoder: Decoder) throws {
            let json = try JSONValue(from: decoder)
            switch json {
            case .array:
                let elements = try Elements(from: decoder)
                self.init(elements)
            default:
                self.init(Elements())
            }
        }
    }

    func testModelListDecoderRegistry() throws {
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.count, 0)
        ModelListDecoderRegistry.registerDecoder(BasicListDecoder.self)
        ModelListDecoderRegistry.registerDecoder(BasicListDecoder.self)
        XCTAssertEqual(ModelListDecoderRegistry.listDecoders.count, 2)
    }

    func testBasicModelListTest() throws {
        ModelListDecoderRegistry.registerDecoder(BasicListDecoder.self)
        let data: JSONValue = [
            ["id": "1"],
            ["id": "2"]
        ]

        let serializedData = try ModelListTests.encode(json: data)
        let list = try ModelListTests.decode(serializedData, responseType: BasicModel.self)
        XCTAssertNotNil(list)
        XCTAssertEqual(list.count, 2)
        guard let basicList = list as? BasicList else {
            XCTFail("Failed to cast to basic list")
            return
        }
        XCTAssertEqual(basicList.count, 2)
    }

    private static func encode(json: JSONValue) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        return try encoder.encode(json)
    }

    private static func decode<R: Decodable>(_ data: Data, responseType: R.Type) throws -> List<R> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        return try decoder.decode(List<R>.self, from: data)
    }
}
