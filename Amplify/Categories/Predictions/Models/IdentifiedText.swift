//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CoreGraphics

/// <#Description#>
public protocol IdentifiedText {

    /// <#Description#>
    var text: String { get }

    /// <#Description#>
    var boundingBox: CGRect { get }

    /// <#Description#>
    var polygon: Polygon? { get }

    /// <#Description#>
    var page: Int? { get }
}
