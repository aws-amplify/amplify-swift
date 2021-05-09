//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct Selection {

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let polygon: Polygon

    /// <#Description#>
    public let isSelected: Bool

    /// <#Description#>
    /// - Parameters:
    ///   - boundingBox: <#boundingBox description#>
    ///   - polygon: <#polygon description#>
    ///   - isSelected: <#isSelected description#>
    public init(boundingBox: CGRect, polygon: Polygon, isSelected: Bool) {
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.isSelected = isSelected
    }
}
