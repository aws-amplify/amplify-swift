//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSTextract

protocol AWSTextractBehavior {
    func analyzeDocument(
        request: AnalyzeDocumentInput
    ) async throws -> AnalyzeDocumentOutputResponse

    func detectDocumentText(
        request: DetectDocumentTextInput
    ) async throws -> DetectDocumentTextOutputResponse

    func getTextract() -> TextractClient
}
