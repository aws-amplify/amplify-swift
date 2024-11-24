//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ChallengeEvent: Codable {
    let version: String
    let type: ChallengeType

    enum CodingKeys: String, CodingKey {
        case version = "Version"
        case type = "Type"
    }
}
