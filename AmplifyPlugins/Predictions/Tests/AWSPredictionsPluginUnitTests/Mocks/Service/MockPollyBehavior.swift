//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
@testable import AWSPredictionsPlugin

class MockPollyBehavior: AWSPollyBehavior {
    var synthesizeSpeechResult: ((SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutputResponse)? = nil

    func synthesizeSpeech(
        request: SynthesizeSpeechInput
    ) async throws -> SynthesizeSpeechOutputResponse {
        guard let synthesizeSpeechResult else { throw MockBehaviorDefaultError() }
        return try await synthesizeSpeechResult(request)
    }

    func getPolly() -> PollyClient {
        try! .init(region: "us-east-1")
    }
}
