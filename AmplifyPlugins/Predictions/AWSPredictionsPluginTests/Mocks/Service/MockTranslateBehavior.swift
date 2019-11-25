//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: AWSTranslateBehavior {

    var result: AWSTranslateTranslateTextResponse?
    var error: Error?

    func translateText(request: AWSTranslateTranslateTextRequest) -> AWSTask<AWSTranslateTranslateTextResponse> {
        if let finalResult = result {
            return AWSTask(result: finalResult)
        }
        return AWSTask(error: error!)
    }

    func getTranslate() -> AWSTranslate {
        return AWSTranslate()
    }

    public func setResult(result: AWSTranslateTranslateTextResponse) {
        self.result = result
        error = nil
    }

    public func setError(error: Error) {
        result = nil
        self.error = error
    }
}
