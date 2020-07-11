//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// struct to decode/encode information about developer environment in json format
struct DevEnvironmentInfo: Codable {
    let nodejsVersion, npmVersion, amplifyCLIVersion, podVersion: String
    let xcodeVersion, osVersion: String

    enum CodingKeys: String, CodingKey {
        case nodejsVersion, npmVersion
        case amplifyCLIVersion = "amplifyCliVersion"
        case podVersion, xcodeVersion, osVersion
    }
}
