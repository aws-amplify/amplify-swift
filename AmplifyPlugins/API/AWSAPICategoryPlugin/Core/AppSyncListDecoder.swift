//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AppSyncListDecoder: ModelListDecoder {

    /// Return true when the incoming payload to decode can be detected as one of the following scenarios:
    ///
    /// 1. When the developer retrieves a list directly, ie. `Amplify.API.query(.paginatedList)` then during decoding
    /// the GraphQL data will be contained inside the `AppSyncListPayload` to include other information pertaining to
    /// original request, useful for perserving the filter and limit that will be used for pagination calls.
    ///
    /// 2. When the developer retrieves a model, ie. `Amplify.API.query(.get)` then during decoding, the GraphQL data
    /// will have metadata added to its array associations. When the array associations get decoded to the List, the
    /// AppSyncListDecoder will detect it as `ModelMetadata` to store the parent association data used for lazy loading
    ///
    /// 3. When the developer retrieves multiple levels of a model, currently by the means of a custom GraphQL document
    /// with the selection set to indicate that they want to retrieve both a model and its children in a single request,
    /// then the nested children of the List type will be decoded to an `AWSAppSyncListResponse` containing the service
    /// fields "items" and "nextToken".
    ///
    /// When using DataStore, which also depends on API, will register `ModelListDecoder`s from their respective
    /// plugins and could result in a scenario in which this method returns true from both decoders.
    /// Although not ideal, the current implementation avoids this by manually defining incoming payloads
    /// (`AppSyncListPayload`, `AppSyncModelMetadata`) and checking to make sure `AWSAppSyncListResponse` do not match
    /// the payloads expected for DataStore's `DataStoreListDecoder`.
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

    public static func getListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                         decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
        if let appSyncListProvider = try getAppSyncListProvider(modelType: modelType, decoder: decoder) {
            return appSyncListProvider.eraseToAnyModelListProvider()
        }

        return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
    }

    static func getAppSyncListProvider<ModelType: Model>(modelType: ModelType.Type,
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
        assert(false, message)
        return nil
    }
}
