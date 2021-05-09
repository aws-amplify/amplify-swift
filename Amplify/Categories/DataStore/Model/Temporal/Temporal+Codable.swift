//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension TemporalSpec where Self: Codable {

    /// <#Description#>
    /// - Parameter decoder: <#decoder description#>
    /// - Throws: <#description#>
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        try self.init(iso8601String: value)
    }

    /// <#Description#>
    /// - Parameter encoder: <#encoder description#>
    /// - Throws: <#description#>
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(iso8601String)
    }

}

extension Temporal.Date: Codable {}
extension Temporal.DateTime: Codable {}
extension Temporal.Time: Codable {}
