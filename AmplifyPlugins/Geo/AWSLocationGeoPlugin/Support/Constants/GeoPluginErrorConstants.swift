//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct GeoPluginErrorConstants {
    static let decodeConfigurationError: GeoPluginErrorString = (
        "Unable to decode configuration",
        "Make sure the plugin configuration is JSONValue")
}

// Recovery Messages
extension GeoPluginErrorConstants {
    static let accessDenied: RecoverySuggestion = "Make sure the resource exists and the user has access."
}
