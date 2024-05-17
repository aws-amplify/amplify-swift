//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AmplifyAWSServiceConfiguration {

    static var platformMapping: [Platform: String] = [:]

    public static func addUserAgentPlatform(_ platform: Platform, version: String) {
        platformMapping[platform] = version
    }

    public enum Platform: String {
        case flutter = "amplify-flutter"
    }
}
