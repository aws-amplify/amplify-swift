//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct PlaceGeometry: Equatable, Decodable {
    var point: [Double]?

    enum CodingKeys: String, CodingKey {
        case point = "Point"
    }
}
