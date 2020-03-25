//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Type-erased wrapper for encoding and decoding `QueryPredicate`
public struct AnyQueryPredicate: Codable {

    public var base: QueryPredicate

    public init(_ base: QueryPredicate) {
        self.base = base
    }

    private enum CodingKeys: CodingKey {
        case metatype, base
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(QueryPredicateType.self, forKey: .metatype)
        self.base = try type.metatype.init(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type(of: base).metatype, forKey: .metatype)
        try base.encode(to: encoder)
    }
}

/// Adds JSON serialization behavior for `AnyQueryPredicate`
extension AnyQueryPredicate {
    /// Converts the `AnyQueryPredicate` instance to a JSON object as `String`.
    /// - Parameters:
    ///   - encoder: an optional JSONEncoder to use to encode the model. Defaults to `JSONEncoder()`, using a
    ///     custom date formatter that encodes ISO8601 dates with fractional seconds
    /// - Returns: the JSON representation of the `Model`
    /// - seealso: https://developer.apple.com/documentation/foundation/jsonencoder/2895034-encode
    public func toJSON(encoder: JSONEncoder? = nil) throws -> String {
        let resolvedEncoder: JSONEncoder
        if let encoder = encoder {
            resolvedEncoder = encoder
        } else {
            resolvedEncoder = JSONEncoder(dateEncodingStrategy: ModelDateFormatting.encodingStrategy)
        }

        let data = try resolvedEncoder.encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw DataStoreError.decodingError(
                "Invalid UTF-8 Data object. Could not convert encoded QueryPredicate into a valid UTF-8 JSON string",
                "Check if your QueryPredicate doesn't contain any value with invalid UTF-8 characters."
            )
        }

        return json
    }

    /// De-serialize a JSON string into an instance of the concrete type that conforms
    /// to the `AnyQueryPredicate` struct.
    ///
    /// - Parameters:
    ///   - json: a valid JSON object as `String`
    ///   - decoder: an optional JSONDecoder to use to decode the model. Defaults to `JSONDecoder()`, using a
    ///     custom date formatter that decodes ISO8601 dates both with and without fractional seconds
    /// - Returns: an instance of the concrete type conforming to `Model`
    /// - Throws: `DecodingError.dataCorrupted` in case data is not a valid JSON or any
    /// other decoding specific error that `JSONDecoder.decode()` might throw.
    public static func from(json: String,
                            decoder: JSONDecoder? = nil) throws -> Self {
        let resolvedDecoder: JSONDecoder
        if let decoder = decoder {
            resolvedDecoder = decoder
        } else {
            resolvedDecoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)
        }

        guard let data = json.data(using: .utf8) else {
            throw DataStoreError.decodingError(
                "Invalid JSON string. Could not convert the passed JSON string into a UTF-8 Data object",
                "Ensure the JSON doesn't contain any invalid UTF-8 data:\n\n\(json)"
            )
        }

        return try resolvedDecoder.decode(Self.self, from: data)
    }
}
