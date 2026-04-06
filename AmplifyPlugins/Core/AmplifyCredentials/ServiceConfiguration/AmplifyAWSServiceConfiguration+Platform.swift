//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension AmplifyAWSServiceConfiguration {

    internal static var platformMapping: [Platform: String] = [:]

    static func addUserAgentPlatform(_ platform: Platform, version: String) {
        platformMapping[platform] = version
    }

    enum Platform: String {
        case flutter = "amplify-flutter"
    }
}
