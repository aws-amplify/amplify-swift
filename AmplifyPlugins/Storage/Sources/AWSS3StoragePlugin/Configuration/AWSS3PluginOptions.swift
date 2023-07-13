//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// - Tag: AWSS3PluginOptions
struct AWSS3PluginOptions {

    /// - Tag: AWSS3PluginOptionsCodingKeys
    enum CodingKeys: String, CodingKey {
        
        /// See: https://docs.amplify.aws/lib/storage/transfer-acceleration/q/platform/js/
        /// - Tag: AWSS3PluginOptionsCodingKeys.useAccelerateEndpoint
        case useAccelerateEndpoint
    }

    /// Attempts to extract the boolean under the
    /// [useAccelerateEndpoint](x-source-tag://AWSS3PluginOptionsCodingKeys.useAccelerateEndpoint)
    /// contained in the given dictionary.
    ///
    /// In other words,  a non-nil boolean is returned if:
    ///
    /// * The `pluginOptions` parameter is a dictionary ([String: Any])
    /// * The `pluginOptions` dictionary contains a boolean key under the [useAccelerateEndpoint](x-source-tag://AWSS3PluginOptionsCodingKeys.useAccelerateEndpoint) key.
    ///
    /// - Tag: AWSS3PluginOptions.accelerateValue
    static func accelerateValue(pluginOptions: Any?) throws -> Bool? {
        guard let pluginOptions = pluginOptions as? [String:Any] else {
            return nil
        }
        guard let value = pluginOptions[CodingKeys.useAccelerateEndpoint.rawValue] else {
            return nil
        }
        guard let boolValue = value as? Bool else {
            throw StorageError.validation(CodingKeys.useAccelerateEndpoint.rawValue,
                                          "Expecting boolean value for key \(CodingKeys.useAccelerateEndpoint.rawValue)",
                                          "Ensure the value associated with \(CodingKeys.useAccelerateEndpoint.rawValue) is a boolean",
                                          nil)
        }
        return boolValue
    }
}
