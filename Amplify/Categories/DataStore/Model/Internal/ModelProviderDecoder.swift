//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// MARK: ModelProviderRegistry

public struct ModelProviderRegistry {
    public static var decoders = AtomicValue(initialValue: [ModelProviderDecoder.Type]())

    /// Register a decoder during plugin configuration time, to allow runtime retrievals of list providers.
    public static func registerDecoder(_ decoder: ModelProviderDecoder.Type) {
        decoders.append(decoder)
    }
}

extension ModelProviderRegistry {
    static func reset() {
        decoders.set([ModelProviderDecoder.Type]())
    }
}

public protocol ModelProviderDecoder {
    static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool
    static func makeModelProvider<ModelType: Model>(
        modelType: ModelType.Type, decoder: Decoder) throws -> AnyModelProvider<ModelType>
}
