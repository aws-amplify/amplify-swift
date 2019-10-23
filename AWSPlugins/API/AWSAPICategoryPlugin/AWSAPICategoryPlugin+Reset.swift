//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

public extension AWSAPICategoryPlugin {
    func reset(onComplete: @escaping (() -> Void)) {
        httpTransport = nil
        onComplete()
    }
}
