//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AppSyncList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    var storedElements: [Element]

    public override
    var elements: Elements {
        storedElements
    }

    // MARK: - Initializers

    init(_ elements: Elements) {
        self.storedElements = elements
        super.init()
    }

    // MARK: - ExpressibleByArrayLiteral

    required convenience init(arrayLiteral elements: List<ModelType>.Element...) {
        self.init(elements)
    }

    // MARK: Collection conformance

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

    public override __consuming func makeIterator() -> IndexingIterator<Elements> {
        return elements.makeIterator()
    }

    // MARK: Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        if case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] {

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements)
            return
        }

        self.init([ModelType]())
    }

    public override func encode(to encoder: Encoder) throws {
        try elements.encode(to: encoder)
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }
        return shouldDecode(json: json)
    }

    static func shouldDecode(json: JSONValue) -> Bool {
        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        }

        return false
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) throws -> List<ModelType> {
        try AppSyncList<ModelType>.init(from: decoder)
    }
}
