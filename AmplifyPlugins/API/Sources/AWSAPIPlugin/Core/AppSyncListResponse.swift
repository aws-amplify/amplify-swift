//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Resembles the AppSync's GraphQL response for a list operation.
struct AppSyncListResponse<Element: Model>: Codable {
    public let items: [Element]
    public let nextToken: String?

    init(items: [Element], nextToken: String? = nil) {
        self.items = items
        self.nextToken = nextToken
    }
}

extension AppSyncListResponse {

    /// Modify the incoming `graphQLData` by decoding each item in the response with
    /// model metadata on its array associations.
    static func initWithMetadata(type: Element.Type,
                                 graphQLData: JSONValue,
                                 apiName: String?) throws -> AppSyncListResponse<Element> {
        var elements = [Element]()
        if case let .array(jsonArray) = graphQLData["items"] {
            let jsonArrayWithMetadata = AppSyncModelMetadataUtils.addMetadata(toModelArray: jsonArray, apiName: apiName)

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            elements = try jsonArrayWithMetadata.map { jsonElement -> Element in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(type, from: serializedJSON)
            }
        }

        if case let .string(nextToken) = graphQLData["nextToken"] {
            return AppSyncListResponse(items: elements, nextToken: nextToken)
        }

        return AppSyncListResponse(items: elements)
    }

}

// MARK: - AppSyncModelResponse
//
//struct AppSyncModelResponse<Element: Model>: Codable {
//
//    public let item: Element?
//    
//    init(item: Element?) {
//        self.item = item
//    }
//}
//
//extension AppSyncModelResponse {
//    static func initWithMetadata(type: Element.Type,
//                                 graphQLData: JSONValue,
//                                 apiName: String?) throws -> AppSyncModelResponse<Element> {
//        
//        var element: Element? = nil
//        if case let .object = graphQLData {
//            let jsonObjectWithMetadata = AppSyncModelMetadataUtils.addMetadata(toModel: graphQLData, apiName: apiName)
//            
//            let encoder = JSONEncoder()
//            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
//            let serializedJSON = try encoder.encode(jsonObjectWithMetadata)
//            element = try decoder.decode(type, from: serializedJSON)
//        }
//        
//        return AppSyncModelResponse(item: element)
//    }
//    
//}
