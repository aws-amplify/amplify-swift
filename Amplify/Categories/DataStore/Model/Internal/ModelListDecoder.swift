//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Registry of `ModelListDecoder`'s used to retrieve decoders for checking if decodable `List<ModelType>` subclasses.
/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public struct ModelListDecoderRegistry {
    public static var listDecoders: [ModelListDecoder.Type] = []

    /// Register a decoder when the plugin is configured to be used for custom decoding to plugin subclasses of
    /// `List<ModelType>`.
    public static func registerDecoder(_ listDecoder: ModelListDecoder.Type) {
        listDecoders.append(listDecoder)
    }
}

/// `ModelListDecoder` provides decodability checking and decoding functionality.
/// - Warning: Although this has `public` access, it is intended for internal use and should not be used directly
///   by host applications. The behavior of this may change without warning.
public protocol ModelListDecoder {
    static func shouldDecode(decoder: Decoder) -> Bool
    static func decode<ModelType: Model>(decoder: Decoder,
                                         modelType: ModelType.Type) -> List<ModelType>
}
