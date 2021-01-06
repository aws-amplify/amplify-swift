//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTextract

class AWSTextractAdapter: AWSTextractBehavior {

    let awsTextract: AWSTextract

    init(_ awsTextract: AWSTextract) {
        self.awsTextract = awsTextract
    }

    func analyzeDocument(request: AWSTextractAnalyzeDocumentRequest) -> AWSTask<AWSTextractAnalyzeDocumentResponse> {
        awsTextract.analyzeDocument(request)
    }

    func detectDocumentText(
        request: AWSTextractDetectDocumentTextRequest) -> AWSTask<AWSTextractDetectDocumentTextResponse> {
        awsTextract.detectDocumentText(request)
    }

    func getTextract() -> AWSTextract {
        return awsTextract
    }

}
