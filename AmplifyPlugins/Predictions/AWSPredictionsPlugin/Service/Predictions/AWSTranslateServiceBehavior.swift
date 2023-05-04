//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSTranslate

protocol AWSTranslateServiceBehavior {
    func translateText(
        text: String,
        language: Predictions.Language?,
        targetLanguage: Predictions.Language?
    ) async throws -> Predictions.Convert.TranslateText.Result
}
