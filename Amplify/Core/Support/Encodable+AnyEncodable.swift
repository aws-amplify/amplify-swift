//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AnyEncodable: Encodable {

    let encodable: Encodable

    init(_ encodable: Encodable) {
        self.encodable = encodable
    }

    /// <#Description#>
    /// - Parameter encoder: <#encoder description#>
    /// - Throws: <#description#>
    public func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

extension Encodable {

    /// <#Description#>
    /// - Returns: <#description#>
    public func eraseToAnyEncodable() -> AnyEncodable {
        return AnyEncodable(self)
    }

}
