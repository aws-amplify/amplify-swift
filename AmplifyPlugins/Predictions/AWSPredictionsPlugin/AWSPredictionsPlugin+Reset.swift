//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AWSPredictionsPlugin {
    func reset() async {
        if predictionsService != nil {
            let resettable = predictionsService as Resettable
            await resettable.reset()
            predictionsService = nil
        }

        if authService != nil {
            if let resettable = authService as? Resettable {
                await resettable.reset()
            }
            authService = nil
        }
    }
}
