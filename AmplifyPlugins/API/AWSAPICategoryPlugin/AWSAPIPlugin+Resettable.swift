//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AwsCommonRuntimeKit

extension AWSAPIPlugin: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        mapper.reset()

        let waitForReset = DispatchSemaphore(value: 0)
        session.reset { waitForReset.signal() }
        waitForReset.wait()

        session = nil

        pluginConfig = nil

        authService = nil

        reachabilityMapLock.execute {
                reachabilityMap.removeAll()
        }

        subscriptionConnectionFactory = nil

        AwsCommonRuntimeKit.cleanUp()
        
        onComplete()
    }

}
