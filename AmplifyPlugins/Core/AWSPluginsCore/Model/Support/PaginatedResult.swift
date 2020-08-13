//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol PaginatedResultDecodable { }

public class PaginatedResult<ModelType: Model>: Decodable, PaginatedResultDecodable {
    private let items: [ModelType]
    private let nextToken: String?
    private let document: String?
    private let variables: [String: JSONValue]?

    init(_ items: [ModelType],
                nextToken: String? = nil,
                document: String? = nil,
                variables: [String: JSONValue]? = nil) {
        self.items = items
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
    }

    /// Retrieve the list of items for this page
    public func getItems() -> [ModelType] {
        return items
    }

    /// Check if there is another page of results
    public func hasNextResult() -> Bool {
        return nextToken != nil
    }

    /// Retrieve the GraphQLRequest to perform querying the next page of results
    public func getRequestForNextResult() -> GraphQLRequest<PaginatedResult<ModelType>> {
        guard let nextToken = nextToken, let document = document else {
            fatalError("getRequestForNextResult called for missing nextToken")
        }

        if var variables = variables {
            variables.updateValue(.string(nextToken), forKey: "nextToken")
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            if let variablesData = try? encoder.encode(variables),
                let variablesJSON = try? JSONSerialization.jsonObject(with: variablesData) as? [String: Any] {
                return GraphQLRequest<PaginatedResult<ModelType>>(document: document,
                                                                  variables: variablesJSON,
                                                                  responseType: PaginatedResult<ModelType>.self)
            }
        }
        return GraphQLRequest<PaginatedResult<ModelType>>(document: document,
                                                          variables: ["nextToken": nextToken],
                                                          responseType: PaginatedResult<ModelType>.self)

    }

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        if let paginatedResultData = try? PaginatedResultData.init(from: decoder) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try paginatedResultData.getItems().map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements,
                      nextToken: paginatedResultData.getNextToken(),
                      document: paginatedResultData.document,
                      variables: paginatedResultData.variables)
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

/// `PaginatedResultData` is used internally to store GraphQL request related information, alongside the GraphQL
/// response's decodable payload. This is used alongside APIPlugin's deserialization logic by generating a
/// `PaginatedResult` to be deserialized into the final `PaginatedResult` response to the caller.
///
/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public struct PaginatedResultData: Codable {
    let document: String
    let variables: [String: JSONValue]?
    private let graphQLData: JSONValue

    public init(document: String, variables: [String: JSONValue]? = nil, graphQLData: JSONValue) {
        self.document = document
        self.variables = variables
        self.graphQLData = graphQLData
    }

    public func getNextToken() -> String? {
        if case let .string(nextToken) = graphQLData["nextToken"] {
            return nextToken
        }

        return nil
    }

    public func getItems() -> [JSONValue] {
        if case let .array(jsonArray) = graphQLData["items"] {
            return jsonArray
        }

        return []
    }
}
