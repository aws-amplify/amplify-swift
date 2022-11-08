//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AppSyncListDecoder: ModelListDecoder {

    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if (try? AppSyncListPayload(from: decoder)) != nil {
            return true
        }

        if (try? AppSyncModelMetadata(from: decoder)) != nil {
            return true
        }

        if (try? AppSyncListResponse<ModelType>(from: decoder)) != nil {
            return true
        }

        return false
    }

    public static func makeListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                          decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
        if let appSyncListProvider = try makeAppSyncListProvider(modelType: modelType, decoder: decoder) {
            return appSyncListProvider.eraseToAnyModelListProvider()
        }

        return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
    }

    static func makeAppSyncListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                   decoder: Decoder) throws -> AppSyncListProvider<ModelType>? {
        if let listPayload = try? AppSyncListPayload.init(from: decoder) {
            return try AppSyncListProvider(payload: listPayload)
        } else if let metadata = try? AppSyncModelMetadata.init(from: decoder) {
            return AppSyncListProvider<ModelType>(metadata: metadata)
        } else if let listResponse = try? AppSyncListResponse<ModelType>.init(from: decoder) {
            return try AppSyncListProvider<ModelType>(listResponse: listResponse)
        }

        let json = try JSONValue(from: decoder)
        let message = "AppSyncListProvider could not be created from \(String(describing: json))"
        Amplify.DataStore.log.error(message)
        assertionFailure(message)
        return nil
    }
}


public struct AppSyncModelDecoder: ModelProviderDecoder {
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if (try? AppSyncModelIdentifierMetadata(from: decoder)) != nil {
            return true
        }
        
        if (try? ModelType(from: decoder)) != nil {
            return true
        }
        
        return false
    }
    
    public static func makeModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                           decoder: Decoder) throws -> AnyModelProvider<ModelType> {
        if let appSyncModelProvider = try makeAppSyncModelProvider(modelType: modelType, decoder: decoder) {
            return appSyncModelProvider.eraseToAnyModelProvider()
        }

        return DefaultModelProvider<ModelType>().eraseToAnyModelProvider()
    }
    
    static func makeAppSyncModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                           decoder: Decoder) throws -> AppSyncModelProvider<ModelType>? {
        if let model = try? ModelType.init(from: decoder) {
            return AppSyncModelProvider(model: model)
        } else if let metadata = try? AppSyncModelIdentifierMetadata.init(from: decoder) {
            return AppSyncModelProvider<ModelType>(metadata: metadata)
        }
        let json = try JSONValue(from: decoder)
        let message = "AppSyncModelProvider could not be created from \(String(describing: json))"
        Amplify.DataStore.log.error(message)
        assertionFailure(message)
        return nil
    }
}
