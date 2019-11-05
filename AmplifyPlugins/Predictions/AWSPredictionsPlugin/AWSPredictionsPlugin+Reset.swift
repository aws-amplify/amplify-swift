//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

extension AWSPredictionsPlugin {

    public func reset(onComplete: @escaping BasicClosure) {
        if rekognitionService != nil {
            rekognitionService.reset()
            rekognitionService = nil
        }
        if translateService != nil {
            translateService.reset()
            translateService = nil
        }
        if authService != nil {
            authService.reset()
            authService = nil
        }

        if queue != nil {
            queue = nil
        }

        onComplete()
    }
}
