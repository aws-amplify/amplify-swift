//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCore
import AWSTextract
@testable import AWSPredictionsPlugin

class MockTextractBehavior: AWSTextractBehavior {

    var analyzeDocument: AWSTextractAnalyzeDocumentResponse?
    var detectDocumentText: AWSTextractDetectDocumentTextResponse?
    var error: Error?

    func analyzeDocument(request: AWSTextractAnalyzeDocumentRequest) -> AWSTask<AWSTextractAnalyzeDocumentResponse> {
        guard let finalError = error else {
            return AWSTask(result: analyzeDocument)
        }
        return AWSTask(error: finalError)
    }

    func detectDocumentText(request: AWSTextractDetectDocumentTextRequest)
    -> AWSTask<AWSTextractDetectDocumentTextResponse> {
        guard let finalError = error else {
            return AWSTask(result: detectDocumentText)
        }
        return AWSTask(error: finalError)
    }

    func getTextract() -> AWSTextract {
        return AWSTextract()
    }

    public func setAnalyzeDocument(result: AWSTextractAnalyzeDocumentResponse?) {
        analyzeDocument = result
        error = nil
    }

    public func setDetectDocumentText(result: AWSTextractDetectDocumentTextResponse?) {
        detectDocumentText = result
        error = nil
    }

    public func setError(error: Error) {
        analyzeDocument = nil
        detectDocumentText = nil
        self.error = error
    }
}
