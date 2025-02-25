//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// A struct to store preferences for how the plugin uses storage
public struct AWSCognitoSecureStoragePreferences {

    /// The access group that the keychain will use for auth items
    public let accessGroup: AccessGroup?

    /// Creates an intstance of AWSCognitoSecureStoragePreferences
    /// - Parameters:
    ///   - accessGroup: access group to be used
    public init(accessGroup: AccessGroup? = nil) {
        self.accessGroup = accessGroup
    }
}
