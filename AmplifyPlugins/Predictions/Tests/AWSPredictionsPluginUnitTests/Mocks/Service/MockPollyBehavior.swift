//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPolly
@testable import AWSPredictionsPlugin

class MockPollyBehavior: PollyClientProtocol {
    var synthesizeSpeechResult: ((SynthesizeSpeechInput) async throws -> SynthesizeSpeechOutput)? = nil

    func synthesizeSpeech(
        input: SynthesizeSpeechInput
    ) async throws -> SynthesizeSpeechOutput {
        guard let synthesizeSpeechResult else { throw MockBehaviorDefaultError() }
        return try await synthesizeSpeechResult(input)
    }

    func getPolly() -> PollyClient {
        try! .init(region: "us-east-1")
    }
}

// MARK: Unused PolliClientProtocol Methods
extension MockPollyBehavior {
    func deleteLexicon(input: AWSPolly.DeleteLexiconInput) async throws -> AWSPolly.DeleteLexiconOutput { fatalError() }
    func describeVoices(input: AWSPolly.DescribeVoicesInput) async throws -> AWSPolly.DescribeVoicesOutput { fatalError() }
    func getLexicon(input: AWSPolly.GetLexiconInput) async throws -> AWSPolly.GetLexiconOutput { fatalError() }
    func getSpeechSynthesisTask(input: AWSPolly.GetSpeechSynthesisTaskInput) async throws -> AWSPolly.GetSpeechSynthesisTaskOutput { fatalError() }
    func listLexicons(input: AWSPolly.ListLexiconsInput) async throws -> AWSPolly.ListLexiconsOutput { fatalError() }
    func listSpeechSynthesisTasks(input: AWSPolly.ListSpeechSynthesisTasksInput) async throws -> AWSPolly.ListSpeechSynthesisTasksOutput { fatalError() }
    func putLexicon(input: AWSPolly.PutLexiconInput) async throws -> AWSPolly.PutLexiconOutput { fatalError() }
    func startSpeechSynthesisTask(input: AWSPolly.StartSpeechSynthesisTaskInput) async throws -> AWSPolly.StartSpeechSynthesisTaskOutput { fatalError() }
}
