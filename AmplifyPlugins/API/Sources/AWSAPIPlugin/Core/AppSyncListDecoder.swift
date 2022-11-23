//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// This decoder is registered and used to detect various data payloads objects to store
/// inside an AppSyncListProvider when decoding to the Lazy `List` type as a "not yet loaded" List. If the data payload
/// can be decoded to the list, then the list provider is created as a "loaded" list
public struct AppSyncListDecoder: ModelListDecoder {

    /// Metadata that contains information about an associated parent object.
    struct Metadata: Codable {
        let appSyncAssociatedIdentifiers: [String]
        let appSyncAssociatedField: String
        let apiName: String?
    }
    
    /// Used by the custom decoder implemented in the `List` type to detect if the payload can be
    /// decoded to an AppSyncListProvider.
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if (try? AppSyncListPayload(from: decoder)) != nil {
            return true
        }

        if (try? Metadata(from: decoder)) != nil {
            return true
        }

        if (try? AppSyncListResponse<ModelType>(from: decoder)) != nil {
            return true
        }

        return false
    }

    /// Create an AppSyncListProvider in different states, such as a "not loaded" provider with metadata
    /// or a "loaded" list with the response data items, or the response with "next token"
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
            log.verbose("Creating loaded list of \(modelType.modelName)")
            return try AppSyncListProvider(payload: listPayload)
        } else if let metadata = try? Metadata.init(from: decoder) {
            log.verbose("Creating not loaded list of \(modelType.modelName) with \(metadata)")
            return AppSyncListProvider<ModelType>(metadata: metadata)
        } else if let listResponse = try? AppSyncListResponse<ModelType>.init(from: decoder) {
            log.verbose("Creating list response for \(modelType.modelName)")
            return try AppSyncListProvider<ModelType>(listResponse: listResponse)
        }

        let json = try JSONValue(from: decoder)
        let message = "AppSyncListProvider could not be created from \(String(describing: json))"
        log.error(message)
        assertionFailure(message)
        return nil
    }
}

extension AppSyncListDecoder: DefaultLogger { }
