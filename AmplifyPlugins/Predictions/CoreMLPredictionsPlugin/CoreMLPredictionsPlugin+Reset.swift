//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension CoreMLPredictionsPlugin {

    public func reset(onComplete: @escaping BasicClosure) {

        queue = nil
        coreMLNaturalLanguage = nil
        coreMLSpeech = nil
        coreMLVision = nil
        onComplete()
    }
}
