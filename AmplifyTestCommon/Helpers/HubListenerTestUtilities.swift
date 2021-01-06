//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

struct HubListenerTestUtilities {

    /// Blocks current thread until the listener with `token` is attached to the plugin. Returns `true` if the listener
    /// becomes present before the `timeout` expires, `false` otherwise.
    ///
    /// - Parameter token: the token identifying the listener to wait for
    /// - Parameter plugin: the plugin on which the listener will be checked
    /// - Parameter timeout: the maximum length of time to wait for the listener to be registered
    /// - Throws: if the plugin cannot be cast to `AWSHubPlugin`
    static func waitForListener(with token: UnsubscribeToken,
                                plugin: HubCategoryPlugin? = nil,
                                timeout: TimeInterval,
                                file: StaticString = #file,
                                line: UInt = #line) throws -> Bool {

        let plugin = try plugin ?? Amplify.Hub.getPlugin(for: AWSHubPlugin.key)

        guard let resolvedPlugin = plugin as? AWSHubPlugin else {
            throw "Could not cast plugin as AWSHubPlugin (\(file) L\(line))"
        }

        var hasListener = false

        let deadline = Date(timeIntervalSinceNow: timeout)
        while !hasListener && Date() < deadline {
            if resolvedPlugin.hasListener(withToken: token) {
                hasListener = true
                break
            }
            Thread.sleep(forTimeInterval: 0.01)
        }

        return hasListener
    }

}
