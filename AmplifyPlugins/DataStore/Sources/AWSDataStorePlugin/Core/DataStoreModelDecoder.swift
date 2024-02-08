//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SQLite

public struct DataStoreModelDecoder: ModelProviderDecoder {

    public static let DataStoreSource = "DataStore"

    /// Metadata that contains the foreign key value of a parent model, which is the primary key of the model to be loaded.
    struct Metadata: Codable {
        let identifiers: [LazyReferenceIdentifier]
        let source: String

        init(identifiers: [LazyReferenceIdentifier], source: String = DataStoreSource) {
            self.identifiers = identifiers
            self.source = source
        }

        func toJsonObject() -> Any? {
            try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))
        }
    }

    /// Create a SQLite payload that is capable of initializting a LazyReference, by decoding to `DataStoreModelDecoder.Metadata`.
    static func lazyInit(identifiers: [LazyReferenceIdentifier]) -> Metadata? {
        if identifiers.isEmpty {
            return nil
        }
        return Metadata(identifiers: identifiers)
    }

    public static func decode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AnyModelProvider<ModelType>? {
        if let metadata = try? DataStoreModelDecoder.Metadata(from: decoder) {
            if metadata.source == DataStoreSource {
                return DataStoreModelProvider<ModelType>(metadata: metadata).eraseToAnyModelProvider()
            } else {
                return nil
            }
        }

        if let model = try? ModelType.init(from: decoder) {
            return DataStoreModelProvider(model: model).eraseToAnyModelProvider()
        }

        // This case can happen when a model is deleted remotely, and the reconciliation doesn't
        // have the local model to pass back. Hence we would need to decode the Remote Model which is in the following format
        // "post":[{"name":"id","value":"3"}]
        // Which is very different comparing to DataStoreModelDecoder.Metadata is expecting from the local data store.
        if var container = try? decoder.unkeyedContainer() {
            var identifiers = [LazyReferenceIdentifier]()
            while !container.isAtEnd {
                if let identifier = try? container.decode(LazyReferenceIdentifier.self) {
                    identifiers.append(identifier)
                }
            }
            if !identifiers.isEmpty {
                return DataStoreModelProvider<ModelType>(
                    metadata: .init(identifiers: identifiers,
                                    source: DataStoreSource)
                ).eraseToAnyModelProvider()
            }
        }
        return nil
    }
}
