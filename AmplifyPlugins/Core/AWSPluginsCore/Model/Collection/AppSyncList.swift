//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public class AppSyncList<ModelType: Model>: List<ModelType> {

    let nextToken: String?
    let document: String?
    let variables: [String: JSONValue]?

    // MARK: - Initializers

    init(_ elements: [Element],
         nextToken: String? = nil,
         document: String? = nil,
         variables: [String: JSONValue]? = nil) {
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
        super.init(elements, associatedId: nil, associatedField: nil)
    }

    required convenience init(arrayLiteral elements: List<ModelType>.Element...) {
        self.init(elements)
    }

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        if let payload = try? AppSyncListPayload.init(from: decoder) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try payload.getItems().map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements,
                      nextToken: payload.getNextToken(),
                      document: payload.document,
                      variables: payload.variables)
            return
        }

        guard case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] else {
            self.init([ModelType]())
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        let elements = try jsonArray.map { (jsonElement) -> ModelType in
            let serializedJSON = try encoder.encode(jsonElement)
            return try decoder.decode(ModelType.self, from: serializedJSON)
        }

        self.init(elements)
    }
}
