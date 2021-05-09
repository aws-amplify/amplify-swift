//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct BoundedKeyValue {

    /// <#Description#>
    public let key: String

    /// <#Description#>
    public let value: String

    /// <#Description#>
    public let isSelected: Bool

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let polygon: Polygon

    /// <#Description#>
    /// - Parameters:
    ///   - key: <#key description#>
    ///   - value: <#value description#>
    ///   - isSelected: <#isSelected description#>
    ///   - boundingBox: <#boundingBox description#>
    ///   - polygon: <#polygon description#>
    public init(key: String, value: String, isSelected: Bool, boundingBox: CGRect, polygon: Polygon) {
        self.key = key
        self.value = value
        self.isSelected = isSelected
        self.boundingBox = boundingBox
        self.polygon = polygon
    }
}
