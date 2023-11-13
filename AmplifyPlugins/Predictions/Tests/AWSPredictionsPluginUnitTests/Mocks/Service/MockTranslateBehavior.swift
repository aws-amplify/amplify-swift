//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPredictionsPlugin

//class MockTranslateBehavior: TranslateClient {
//    var translateTextResult: ((TranslateTextInput) async throws -> TranslateTextOutputResponse)? = nil
//
//    func translateText(
//        input: TranslateTextInput
//    ) async throws -> TranslateTextOutputResponse {
//        guard let translateTextResult else { throw MockBehaviorDefaultError() }
//        return try await translateTextResult(input)
//    }
//
//    func getTranslate() -> AWSTranslate.TranslateClient {
//        try! .init(region: "us-east-1")
//    }
//}
