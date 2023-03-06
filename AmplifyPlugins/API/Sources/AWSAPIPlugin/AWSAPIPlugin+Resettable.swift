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
        mapper.reset()

        await session.cancelAndReset()

        session = nil

        pluginConfig = nil

        authService = nil

        reachabilityMapLock.execute {
                reachabilityMap.removeAll()
        }

        subscriptionConnectionFactory = nil
    }

}
