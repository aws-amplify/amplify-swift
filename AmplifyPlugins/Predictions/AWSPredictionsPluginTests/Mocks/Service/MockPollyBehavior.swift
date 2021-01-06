//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
@testable import AWSPredictionsPlugin

class MockPollyBehavior: AWSPollyBehavior {

    var result: AWSPollySynthesizeSpeechOutput?
    var error: Error?

    func synthesizeSpeech(request: AWSPollySynthesizeSpeechInput) -> AWSTask<AWSPollySynthesizeSpeechOutput> {
        if let finalResult = result {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func getPolly() -> AWSPolly {
        return AWSPolly()
    }

    public func setResult(result: AWSPollySynthesizeSpeechOutput) {
        self.result = result
        error = nil
    }

    public func setError(error: Error) {
        result = nil
        self.error = error
    }
}
