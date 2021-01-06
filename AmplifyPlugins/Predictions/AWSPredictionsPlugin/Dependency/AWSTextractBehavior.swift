//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTextract

protocol AWSTextractBehavior {

    func analyzeDocument(request: AWSTextractAnalyzeDocumentRequest) -> AWSTask<AWSTextractAnalyzeDocumentResponse>

    func detectDocumentText(
        request: AWSTextractDetectDocumentTextRequest) -> AWSTask<AWSTextractDetectDocumentTextResponse>

    func getTextract() -> AWSTextract

}
