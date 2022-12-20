//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// This decoder is registered and used to detect various data payloads to store
/// inside an `AppSyncModelProvider` when decoding to the `LazyReference` as a "not yet loaded" Reference. If the data payload
/// can be decoded to the Model, then the model provider is created as a "loaded" reference.
public struct AppSyncModelDecoder: ModelProviderDecoder {
    
    public static let AppSyncSource = "AppSync"
    
    /// Metadata that contains metadata of a model, specifically the identifiers used to hydrate the model.
    struct Metadata: Codable {
        let identifiers: [LazyReferenceIdentifier]
        let apiName: String?
        let source: String
        
        init(identifiers: [LazyReferenceIdentifier], apiName: String?, source: String = AppSyncSource) {
            self.identifiers = identifiers
            self.apiName = apiName
            self.source = source
        }
    }
    
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AnyModelProvider<ModelType>? {
        if let metadata = try? Metadata(from: decoder) {
            if metadata.source == AppSyncSource {
                log.verbose("Creating not loaded model \(modelType.modelName) with metadata \(metadata)")
                return AppSyncModelProvider<ModelType>(metadata: metadata).eraseToAnyModelProvider()
            } else {
                return nil
            }
        }
        
        if let model = try? ModelType.init(from: decoder) {
            log.verbose("Creating loaded model \(model)")
            return AppSyncModelProvider(model: model).eraseToAnyModelProvider()
        }
        
        return nil
    }
}

extension AppSyncModelDecoder: DefaultLogger { }
