//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSTranslate
@testable import AWSPredictionsPlugin

class MockTranslateBehavior: AWSTranslateBehavior {
    var translateTextResult: ((TranslateTextInput) async throws -> TranslateTextOutputResponse)? = nil

    func translateText(
        request: TranslateTextInput
    ) async throws -> TranslateTextOutputResponse {
        guard let translateTextResult else { throw MockBehaviorDefaultError() }
        return try await translateTextResult(request)
    }

    func getTranslate() -> AWSTranslate.TranslateClient {
        try! .init(region: "us-east-1")
    }
}
