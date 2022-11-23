//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

public struct DataStoreListDecoder: ModelListDecoder {

    /// Creates a data structure that is capable of initializing a `List<M>` with
    /// lazy-load capabilities when the list is being decoded.
    static func lazyInit(associatedId: String, associatedWith: String?) -> [String: Any?] {
        return [
            "associatedId": associatedId,
            "associatedField": associatedWith,
            "elements": []
        ]
    }
    
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }

        return shouldDecode(json: json)
    }

    static func shouldDecode(json: JSONValue) -> Bool {
        if case let .object(list) = json,
           case .string = list["associatedId"],
           case .string = list["associatedField"] {
            return true
        }

        if case .array = json {
            return true
        }

        return false
    }

    public static func makeListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                         decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
        if let provider = try getDataStoreListProvider(modelType: modelType, decoder: decoder) {
            return provider.eraseToAnyModelListProvider()
        }

        return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
    }

    static func getDataStoreListProvider<ModelType: Model>(
        modelType: ModelType.Type,
        decoder: Decoder) throws -> DataStoreListProvider<ModelType>? {
        let json = try? JSONValue(from: decoder)
        switch json {
        case .array:
            let elements = try [ModelType](from: decoder)
            return DataStoreListProvider<ModelType>(elements)
        case .object(let associationData):
            if case let .string(associatedId) = associationData["associatedId"],
               case let .string(associatedField) = associationData["associatedField"] {
                return DataStoreListProvider<ModelType>(associatedIdentifiers: [associatedId],
                                                        associatedField: associatedField)
            }

            let message = "DataStoreListProvider could not be created from \(String(describing: json))"
            Amplify.DataStore.log.error(message)
            assertionFailure(message)
            return nil
        default:
            let message = "DataStoreListProvider could not be created from \(String(describing: json))"
            Amplify.DataStore.log.error(message)
            assertionFailure(message)
            return nil
        }
    }
}
