//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TimeZone: Equatable, Decodable {
    /// This member is required.
    var name: String?
    var offset: Int?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case offset = "Offset"
    }
}
