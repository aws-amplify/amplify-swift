//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Registry of `ModelProviderDecoder`'s used to retrieve decoders that can create `ModelProvider`s to perform
/// LazyReference functionality.
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public struct ModelProviderRegistry {
    public static var decoders = AtomicValue(initialValue: [ModelProviderDecoder.Type]())

    /// Register a decoder during plugin configuration time, to allow runtime retrievals of model providers.
    public static func registerDecoder(_ decoder: ModelProviderDecoder.Type) {
        decoders.append(decoder)
    }
}

extension ModelProviderRegistry {
    static func reset() {
        decoders.set([ModelProviderDecoder.Type]())
    }
}

/// `ModelProviderDecoder` provides decoding and lazy reference functionality.
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol ModelProviderDecoder {
    static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool
    static func makeModelProvider<ModelType: Model>(
        modelType: ModelType.Type, decoder: Decoder) throws -> AnyModelProvider<ModelType>
}
