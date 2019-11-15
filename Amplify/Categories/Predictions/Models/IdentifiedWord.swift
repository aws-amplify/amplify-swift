//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct IdentifiedWord: IdentifiedText {
    public let text: String
    public let boundingBox: BoundingBox
    public let polygon: Polygon?
    public let page: Int?

    public init(text: String, boundingBox: BoundingBox, polygon: Polygon? = nil, page: Int? = nil) {
        self.text = text
        self.boundingBox = boundingBox
        self.polygon = polygon
        self.page = page
    }
}
