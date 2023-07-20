//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct ClientSessionInformationEvent: Codable {
    let challenge: ClientChallenge?

    enum CodingKeys: String, CodingKey {
        case challenge = "Challenge"
    }
}
