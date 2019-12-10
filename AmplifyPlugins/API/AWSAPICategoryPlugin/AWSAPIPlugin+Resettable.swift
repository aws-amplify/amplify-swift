//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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
        _ = waitForReset.wait()

        session = nil

        pluginConfig = nil

        authService = nil

        subscriptionConnectionFactory = nil

        onComplete()
    }

}
