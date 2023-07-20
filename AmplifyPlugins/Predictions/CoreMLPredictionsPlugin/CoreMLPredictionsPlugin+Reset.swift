//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Speech) && canImport(Vision)
import Foundation
import Amplify

extension CoreMLPredictionsPlugin {

    public func reset() async {
        queue = nil
        coreMLNaturalLanguage = nil
        coreMLSpeech = nil
        coreMLVision = nil
    }
}
#endif
