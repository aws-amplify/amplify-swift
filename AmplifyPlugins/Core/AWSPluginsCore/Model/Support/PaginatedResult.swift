//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public protocol PaginatedResultP {
}
public class PaginatedResult<ModelType: Decodable>: Decodable, PaginatedResultP {
    let items: [ModelType]
    let nextToken: String?
    let document: String?
    let variables: [String: JSONValue]?

    public init(_ items: [ModelType],
                nextToken: String? = nil,
                document: String? = nil,
                variables: [String: JSONValue]? = nil) {
        self.items = items
        //self.variables = variables
        self.nextToken = nextToken
        self.document = document
        self.variables = variables
    }

    public func getItems() -> [ModelType] {
        return items
    }

    public func hasNextResult() -> Bool {
        return nextToken != nil
    }

    public func getRequestForNextResult() -> GraphQLRequest<PaginatedResult<ModelType>> {
        guard let nextToken = nextToken, let document = document else {
            fatalError("getRequestForNextResult called for missing nextToken")
        }

        if var variables = variables {
            variables.updateValue(.string(nextToken), forKey: "nextToken")
            return GraphQLRequest<PaginatedResult<ModelType>>(document: document,
                                                              variables: variables,
                                                              responseType: PaginatedResult<ModelType>.self)
        } else {
            return GraphQLRequest<PaginatedResult<ModelType>>(document: document,
                                                              variables: ["nextToken": nextToken],
                                                              responseType: PaginatedResult<ModelType>.self)
        }

    }

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        guard case let .object(jsonObject) = json else {
            self.init([ModelType]())
            return
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy

        if case let .object(dataObject) = jsonObject["__data"],
            case let .object(requestObject) = jsonObject["__request"],
            case let .array(jsonArray) = dataObject["items"],
            case let .string(document) = requestObject["document"],
            case let .object(variables) = requestObject["variables"] {

            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            if case let .string(nextToken) = dataObject["nextToken"] {
                self.init(elements,
                          nextToken: nextToken,
                          document: document,
                          variables: variables)
            } else {
                self.init(elements,
                          document: document,
                          variables: variables)
            }
        } else if case let .array(jsonArray) = jsonObject["items"] {
            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }
            if case let .string(nextToken) = jsonObject["nextToken"] {
                self.init(elements, nextToken: nextToken)
            } else {
                self.init(elements)
            }
        } else {
            self.init([ModelType]())
        }
    }
}

//extension PaginatedResultP {
//    public static func generatePaginatedResultData(graphQLData: JSONValue, document: String) -> PaginatedResultData {
//        return PaginatedResultData()
//    }
//    static func isPaginatedResultData(json: JSONValue) -> Bool {
//        guard case let .object(jsonObject) = json else {
//            return false
//        }
//
//        if case let .object(dataObject) = jsonObject["__data"],
//        case let .object(requestObject) = jsonObject["__request"] {
//
//    }
//}
//
//public struct PaginatedResultData: Codable {
//    public init() {
//
//    }
//}
//
//
