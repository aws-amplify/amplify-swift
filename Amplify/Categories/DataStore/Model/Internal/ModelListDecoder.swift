//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Registry of `ModelListDecoder`'s used to retrieve decoders for checking if decodable `List<ModelType>` subclasses.
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public struct ModelListDecoderRegistry {
    public static var listDecoders: [ModelListDecoder.Type] = []

    /// Register a decoder when the plugin is configured to be used for custom decoding to plugin subclasses of
    /// `List<ModelType>`.
    public static func registerDecoder(_ listDecoder: ModelListDecoder.Type) {
        listDecoders.append(listDecoder)
    }
}

extension ModelListDecoderRegistry {
    static func reset() {
        listDecoders = []
    }
}
/// `ModelListDecoder` provides decodability checking and decoding functionality.
///
/// - Warning: Although this has `public` access, it is intended for internal & codegen use and should not be used
/// directly by host applications. The behavior of this may change without warning. Though it is not used by host
/// application making any change to these `public` types should be backward compatible, otherwise it will be a breaking
/// change.
public protocol ModelListDecoder {
    static func shouldDecode(decoder: Decoder) -> Bool
    static func getListProvider<ModelType: Model>(
        modelType: ModelType.Type, decoder: Decoder) throws -> AnyModelListProvider<ModelType>
}
