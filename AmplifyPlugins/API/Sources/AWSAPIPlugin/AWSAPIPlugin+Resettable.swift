//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
// import AwsCommonRuntimeKit

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

        // Issue: https://github.com/aws-amplify/amplify-ios/issues/2120
        // AwsCommonRuntimeKit.cleanUp()        
    }

}
