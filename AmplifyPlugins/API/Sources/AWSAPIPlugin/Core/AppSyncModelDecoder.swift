//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// This decoder is registered and used to detect various data payloads to store
/// inside an `AppSyncModelProvider` when decoding to the `LazyReference` as a "not yet loaded" Reference. If the data payload
/// can be decoded to the Model, then the model provider is created as a "loaded" reference.
public struct AppSyncModelDecoder: ModelProviderDecoder {

    /// Metadata that contains metadata of a model, specifically the identifiers used to hydrate the model.
    struct Metadata: Codable {
        let identifiers: [LazyReferenceIdentifier]
        let apiName: String?
        let authMode: AWSAuthorizationType?
        let source: String

        init(identifiers: [LazyReferenceIdentifier],
             apiName: String?,
             authMode: AWSAuthorizationType?,
             source: String = ModelProviderRegistry.DecoderSource.appSync) {
            self.identifiers = identifiers
            self.apiName = apiName
            self.authMode = authMode
            self.source = source
        }
    }

    public static func decode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AnyModelProvider<ModelType>? {
        if let metadata = try? Metadata(from: decoder) {
            if metadata.source == ModelProviderRegistry.DecoderSource.appSync {
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

extension AppSyncModelDecoder: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName, forNamespace: String(describing: self))
    }
    public var log: Logger {
        Self.log
    }
}
