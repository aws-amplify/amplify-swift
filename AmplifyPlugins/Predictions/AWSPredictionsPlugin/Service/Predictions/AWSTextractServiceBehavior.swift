//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTextract
import Foundation

protocol AWSTextractServiceBehavior {

    typealias TextractServiceEventHandler = (TextractServiceEvent) -> Void
    typealias TextractServiceEvent = PredictionsEvent<IdentifyResult, PredictionsError>

    func analyzeDocument(
        image: URL,
        features: [String]
    ) async throws -> IdentifyDocumentTextResult

    func detectDocumentText(
        image: Data
    ) async throws -> DetectDocumentTextOutputResponse // (IdentifyResult, AnalyzeDocumentOutputResponse)

}
