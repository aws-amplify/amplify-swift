//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol IdentifiedText {
    var text: String { get }
    var boundingBox: BoundingBox { get }
    var polygon: Polygon { get }
    var page: Int? { get }
}
