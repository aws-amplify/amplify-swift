//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

extension AWSAuthPlugin {

    public func reset(onComplete: @escaping BasicClosure) {
        onComplete()
        // TODO: Verify whether we should recreate awsmobileclient #172336364
    }
}
