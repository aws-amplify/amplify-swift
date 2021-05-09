//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension HubCategory: Resettable {

    /// <#Description#>
    /// - Parameter onComplete: <#onComplete description#>
    public func reset(onComplete: @escaping BasicClosure) {
        let group = DispatchGroup()

        for plugin in plugins.values {
            group.enter()
            plugin.reset { group.leave() }
        }

        group.wait()

        configurationState = .pendingConfiguration
        onComplete()
    }

}
