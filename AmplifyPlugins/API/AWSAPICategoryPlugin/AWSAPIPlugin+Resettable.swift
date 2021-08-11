//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSAPIPlugin: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        mapper.reset()

        mapper = OperationTaskMapper()

        let waitForReset = DispatchSemaphore(value: 0)
        session.reset { waitForReset.signal() }
        waitForReset.wait()

        session = nil

        pluginConfig = nil

        authService = nil

        if #available(iOS 13.0, *) {
            reachabilityMapLock.execute {
                reachabilityMap.removeAll()
            }
        }

        subscriptionConnectionFactory = nil

        onComplete()
    }

}
