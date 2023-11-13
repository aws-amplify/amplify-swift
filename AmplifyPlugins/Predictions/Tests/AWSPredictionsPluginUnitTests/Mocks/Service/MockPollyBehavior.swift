//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPredictionsPlugin

//class MockPollyBehavior: PollyClient {
//    var synthesizeSpeechResult: ((SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutputResponse)? = nil
//
//    func synthesizeSpeech(
//        input: SynthesizeSpeechInput
//    ) async throws -> SynthesizeSpeechOutputResponse {
//        guard let synthesizeSpeechResult else { throw MockBehaviorDefaultError() }
//        return try await synthesizeSpeechResult(input)
//    }
//
//    func getPolly() -> PollyClient {
//        try! .init(region: "us-east-1")
//    }
//}
