//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSAPIPlugin: Resettable {

    public func reset() async {
        if let resettableAppSyncRealClientFactory = appSyncRealTimeClientFactory as? Resettable {
            await resettableAppSyncRealClientFactory.reset()
        }
        appSyncRealTimeClientFactory = nil

        mapper.reset()

        await session.cancelAndReset()

        session = nil

        pluginConfig = nil

        authService = nil

        reachabilityMapLock.execute {
            reachabilityMap.removeAll()
        }
    }

}
