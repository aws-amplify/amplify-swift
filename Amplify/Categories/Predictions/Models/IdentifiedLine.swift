//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public struct IdentifiedLine: IdentifiedText {

    /// <#Description#>
    public let text: String

    /// <#Description#>
    public let boundingBox: CGRect

    /// <#Description#>
    public let polygon: Polygon?

    /// <#Description#>
    public let page: Int?

    /// <#Description#>
    /// - Parameters:
    ///   - text: <#text description#>
    ///   - boundingBox: <#boundingBox description#>
    ///   - polygon: <#polygon description#>
    ///   - page: <#page description#>
    public init(text: String, boundingBox: CGRect, polygon: Polygon? = nil, page: Int? = nil) {
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.page = page
    }
}
