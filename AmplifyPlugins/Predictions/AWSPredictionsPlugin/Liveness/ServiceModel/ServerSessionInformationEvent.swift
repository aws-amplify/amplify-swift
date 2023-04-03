//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ServerSessionInformationEvent: Codable {
    let sessionInformation: SessionInformation

    enum CodingKeys: String, CodingKey {
        case sessionInformation = "SessionInformation"
    }
}
