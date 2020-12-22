//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AppSyncList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    var associatedId: Model.Identifier?
    var associatedField: ModelField?
    var state: LoadState = .pending

    var nextToken: String?
    var document: String?
    var variables: [String: JSONValue]?

    // MARK: - Initializers

    init(_ elements: [Element],
         nextToken: String? = nil,
         document: String? = nil,
         variables: [String: JSONValue]? = nil) {
        super.init(elements)
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
        self.state = .loaded
    }

    public init(_ elements: Elements,
                associatedId: Model.Identifier?,
                associatedField: ModelField?) {
        super.init(elements)
        self.associatedId = associatedId
        self.associatedField = associatedField
    }

    required convenience public init(arrayLiteral elements: Element...) {
        self.init(elements)
        self.state = .loaded
    }

    // MARK: - Collection conformance

    public override var startIndex: Index {
        loadIfNeeded()
        return elements.startIndex
    }

    public __consuming override func makeIterator() -> IndexingIterator<Elements> {
        loadIfNeeded()
        return elements.makeIterator()
    }

    // MARK: Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        // If decodable to `AppSyncListPayload`, extract the request and response
        if let payload = try? AppSyncListPayload.init(from: decoder) {
            // When handling the response, decode each item to the model and store the item's metadata in the array
            // associations
            let elements = try payload.getItems().map { (jsonElement) -> ModelType in
                return try GraphQLResponseDecoder<ModelType>.decodeToModelWithArrayAssociations(
                    responseType: ModelType.self,
                    modelGraphQLData: jsonElement)
            }

            self.init(elements,
                      nextToken: payload.getNextToken(),
                      document: payload.document,
                      variables: payload.variables)
            return
        }

        // Decode to a collection of elements when detected the "items" response from AppSync
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

        // Decode to an empty collection with metadata about the associated field and id
        // The metadata is useful for fetching the first page
        if case let .object(jsonObject) = json,
                  case let .string(associatedId) = jsonObject["associatedId"],
                  case let .string(associatedField) = jsonObject["associatedField"],
                  case .string = jsonObject["listType"] {
            let field = Element.schema.field(withName: associatedField)
            self.init([], associatedId: associatedId, associatedField: field)
            return
        }

        self.init([ModelType]())
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        let json = try? JSONValue(from: decoder)

        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        } else if case let .object(jsonObject) = json,
                  case .string = jsonObject["associatedId"],
                  case .string = jsonObject["associatedField"],
                  case .string(let listType) = jsonObject["listType"],
                  listType == "appSyncList" {
            return true
        }

        do {
            _ = try AppSyncListPayload.init(from: decoder)
            return true
        } catch {
            return false
        }
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) -> List<ModelType> {
        do {
            return try AppSyncList<ModelType>.init(from: decoder)
        } catch {
            return List([ModelType]())
        }
    }

    // MARK: - Asynchronous API

    public override func fetch(_ completion: @escaping (Result<Void, CoreError>) -> Void) {
        if state != .loaded {
            firstPage(completion)
        } else {
            completion(.success(()))
        }
    }

    // MARK: Paginatable

    public override func hasNextPage() -> Bool {
        loadIfNeeded()
        return nextToken != nil
    }

    public override func getNextPage(completion: @escaping PageResultCallback) {
        nextPage(completion: completion)
    }
}
