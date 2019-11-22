//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Adds JSON serialization behavior to all types that conform to the `Model` protocol.
extension Model where Self: Codable {

    /// De-serialize a JSON string into an instance of the concrete type that conforms
    /// to the `Model` protocol.
    ///
    /// - Parameters:
    ///   - json: a valid JSON object as `String`
    ///   - decoder: an optional JSONDecoder to use to decode the model. Defaults to `JSONDecoder()`
    /// - Returns: an instance of the concrete type conforming to `Model`
    /// - Throws: `DecodingError.dataCorrupted` in case data is not a valid JSON or any
    /// other decoding specific error that `JSONDecoder.decode()` might throw.
    public static func from(json: String,
                            decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        guard let data = json.data(using: .utf8) else {
            throw DataStoreError.decodingError(
                "Invalid JSON string. Could not convert the passed JSON string into a UTF-8 Data object",
                "Ensure the JSON doesn't contain any invalid UTF-8 data:\n\n\(json)"
            )
        }
        return try decoder.decode(Self.self, from: data)
    }

    /// De-serialize a `Dictionary` into an instance of the concrete type that conforms
    /// to the `Model` protocol.
    ///
    /// - Parameter dictionary: containing keys and values that match the target type
    /// - Returns: an instance of the concrete type conforming to `Model`
    /// - Throws: `DecodingError.dataCorrupted` in case data is not a valid JSON or any
    /// other decoding specific error that `JSONDecoder.decode()` might throw.
    public static func from(dictionary: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Self.self, from: data)
    }

    /// Converts the `Model` instance to a JSON object as `String`.
    /// - Returns: the JSON representation of the `Model`
    /// - seealso: https://developer.apple.com/documentation/foundation/jsonencoder/2895034-encode
    public func toJSON() throws -> String {
        let data = try JSONEncoder().encode(self)
        guard let json = String(data: data, encoding: .utf8) else {
            throw DataStoreError.decodingError(
                "Invalid UTF-8 Data object. Could not convert the encoded Model into a valid UTF-8 JSON string",
                "Check if your Model doesn't contain any value with invalid UTF-8 characters."
            )
        }
        return json
    }
}
