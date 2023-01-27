//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AppSyncListDecoder: ModelListDecoder {

    /// Metadata that contains information about an associated parent object.
    struct Metadata: Codable {
        let appSyncAssociatedIdentifiers: [String]
        let appSyncAssociatedField: String
        let apiName: String?
    }

    /// Used by the custom decoder implemented in the `List` type to detect if the payload can be
    /// decoded to an AppSyncListProvider.
    public static func decode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AnyModelListProvider<ModelType>? {
        shouldDecodeToAppSyncListProvider(modelType: modelType, decoder: decoder)?.eraseToAnyModelListProvider()
    }

    static func shouldDecodeToAppSyncListProvider<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AppSyncListProvider<ModelType>? {
        if let listPayload = try? AppSyncListPayload.init(from: decoder) {
            log.verbose("Creating loaded list of \(modelType.modelName)")
            do {
                return try AppSyncListProvider(payload: listPayload)
            } catch {
                return nil
            }
        } else if let metadata = try? Metadata.init(from: decoder) {
            log.verbose("Creating not loaded list of \(modelType.modelName) with \(metadata)")
            return AppSyncListProvider<ModelType>(metadata: metadata)
        } else if let listResponse = try? AppSyncListResponse<ModelType>.init(from: decoder) {
            log.verbose("Creating list response for \(modelType.modelName)")
            do {
                return try AppSyncListProvider<ModelType>(listResponse: listResponse)
            } catch {
                return nil
            }
        }

        return nil
    }
}

extension AppSyncListDecoder: DefaultLogger { }
