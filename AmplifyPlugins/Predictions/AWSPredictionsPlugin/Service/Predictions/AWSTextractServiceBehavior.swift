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
    func analyzeDocument(
        image: URL,
        features: [String]
    ) async throws -> Predictions.Identify.DocumentText.Result

    func detectDocumentText(
        image: Data
    ) async throws -> DetectDocumentTextOutputResponse
}
