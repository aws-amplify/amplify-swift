//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: AWSTranslateBehavior {

    var result: AWSTranslateTranslateTextResponse?
    var error: Error?

    func translateText(request: AWSTranslateTranslateTextRequest) -> AWSTask<AWSTranslateTranslateTextResponse> {
        guard let finalError = error else {
            return AWSTask(result: result)
        }
        return AWSTask(error: finalError)
    }

    func getTranslate() -> AWSTranslate {
        return AWSTranslate()
    }

    public func setResult(result: AWSTranslateTranslateTextResponse?) {
        self.result = result
        error = nil
    }

    public func setError(error: Error) {
        result = nil
        self.error = error
    }
}
