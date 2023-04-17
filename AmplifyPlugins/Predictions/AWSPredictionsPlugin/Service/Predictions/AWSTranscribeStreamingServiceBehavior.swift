//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

protocol AWSTranscribeStreamingServiceBehavior {
    func transcribe(
        speechToText: URL,
        language: LanguageType?,
        region: String
    ) async throws -> AsyncThrowingStream<Predictions.Convert.SpeechToText.Result, Error>
}
