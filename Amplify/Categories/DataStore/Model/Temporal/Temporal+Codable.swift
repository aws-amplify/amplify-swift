//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension TemporalSpec where Self: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(iso8601String: value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }

}

extension Temporal.Date: Codable {}
extension Temporal.DateTime: Codable {}
extension Temporal.Time: Codable {}

extension _TemporalSpec where Self: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(iso8601String: value, format: .unknown)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }

}

extension _Temporal.Date: Codable {}
extension _Temporal.DateTime: Codable {}
extension _Temporal.Time: Codable {}
