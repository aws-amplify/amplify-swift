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

    public static func getListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                         decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
        let json = try? JSONValue(from: decoder)
        switch json {
        case .array:
            let elements = try [ModelType](from: decoder)
            return DataStoreListProvider<ModelType>(elements: elements).eraseToAnyModelListProvider()
        case .object(let associationData):
            if case let .string(associatedId) = associationData["associatedId"],
               case let .string(associatedField) = associationData["associatedField"],
               let field = ModelType.schema.field(withName: associatedField) {
                return DataStoreListProvider<ModelType>(associatedId: associatedId,
                                                        associatedField: field).eraseToAnyModelListProvider()
            } else {
                let message = """
                DataStoreListProvider could not be created. Failed to store association data for \(modelType.modelName)
                given: \(associationData)
                """
                Amplify.DataStore.log.error(message)
                assert(false, message)
                return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
            }
        default:
            let message = "DataStoreListProvider could not be created from \(String(describing: json))"
            Amplify.DataStore.log.error(message)
            assert(false, message)
            return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
        }
    }
}
