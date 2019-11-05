//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/*
 Adds JSON serialization behavior to all types that conform to the Model protocol.
 */
extension Model where Self: Codable {
    public static func from(json: String) throws -> Self {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(Self.self, from: data)
    }

    public static func from(dictionary: [String: Any]) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(Self.self, from: data)
    }

    public func toJSON() -> String {
        guard let json = try? JSONEncoder().encode(self) else {
            return "{}"
        }
        return String(data: json, encoding: .utf8)!
    }
}
