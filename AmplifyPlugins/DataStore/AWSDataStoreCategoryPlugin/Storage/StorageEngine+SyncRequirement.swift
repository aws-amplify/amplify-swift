//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

internal extension AuthRules {
    /// Convenience method to check whether we need Auth plugin
    /// - Returns: true  If **any** of the rules uses a provider that requires the Auth plugin, `nil` otherwise
    var requireAuthPlugin: Bool? {
        for rule in self {
            guard let requiresAuthPlugin = rule.requiresAuthPlugin else {
                return nil
            }
            if requiresAuthPlugin {
                return true
            }
        }
        return false
    }
}

internal extension AuthRule {
    var requiresAuthPlugin: Bool? {
        guard let provider = self.provider else {
            return nil
        }

        switch provider {
        // OIDC, Function and API key providers don't need
        // Auth plugin
        case .oidc, .function, .apiKey:
            return false
        case .userPools, .iam:
            return true
        }
    }
}
