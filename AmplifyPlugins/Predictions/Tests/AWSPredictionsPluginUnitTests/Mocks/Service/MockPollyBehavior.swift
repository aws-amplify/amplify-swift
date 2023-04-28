//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
@testable import AWSPredictionsPlugin

class MockPollyBehavior: PollyClientProtocol {
    var synthesizeSpeechResult: ((SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutputResponse)? = nil

    func synthesizeSpeech(
        input: SynthesizeSpeechInput
    ) async throws -> SynthesizeSpeechOutputResponse {
        guard let synthesizeSpeechResult else { throw MockBehaviorDefaultError() }
        return try await synthesizeSpeechResult(input)
    }

    func getPolly() -> PollyClient {
        try! .init(region: "us-east-1")
    }
}

// MARK: Unused PolliClientProtocol Methods
extension MockPollyBehavior {
    func deleteLexicon(input: AWSPolly.DeleteLexiconInput) async throws -> AWSPolly.DeleteLexiconOutputResponse { fatalError() }
    func describeVoices(input: AWSPolly.DescribeVoicesInput) async throws -> AWSPolly.DescribeVoicesOutputResponse { fatalError() }
    func getLexicon(input: AWSPolly.GetLexiconInput) async throws -> AWSPolly.GetLexiconOutputResponse { fatalError() }
    func getSpeechSynthesisTask(input: AWSPolly.GetSpeechSynthesisTaskInput) async throws -> AWSPolly.GetSpeechSynthesisTaskOutputResponse { fatalError() }
    func listLexicons(input: AWSPolly.ListLexiconsInput) async throws -> AWSPolly.ListLexiconsOutputResponse { fatalError() }
    func listSpeechSynthesisTasks(input: AWSPolly.ListSpeechSynthesisTasksInput) async throws -> AWSPolly.ListSpeechSynthesisTasksOutputResponse { fatalError() }
    func putLexicon(input: AWSPolly.PutLexiconInput) async throws -> AWSPolly.PutLexiconOutputResponse { fatalError() }
    func startSpeechSynthesisTask(input: AWSPolly.StartSpeechSynthesisTaskInput) async throws -> AWSPolly.StartSpeechSynthesisTaskOutputResponse { fatalError() }
}
