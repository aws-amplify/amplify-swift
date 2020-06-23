//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Combine

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class PredictionsChainTests: XCTestCase {

    var plugin: MockPredictionsCategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let categoryConfig = PredictionsCategoryConfiguration(
            plugins: ["MockPredictionsCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(predictions: categoryConfig)
        plugin = MockPredictionsCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(amplifyConfig)
    }

    func testChainedOperationsSucceed() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.convertSpeechToText = { _, _ in
            .success(SpeechToTextResult(transcription: "Hello"))
        }

        plugin.responders.convertTextToTranslate = { _, _, _, _ in
            .success(TranslateTextResult(text: "Hola", targetLanguage: .spanish))
        }

        plugin.responders.convertTextToSpeech = { _, _ in
            .success(TextToSpeechResult(audioData: Data()))
        }

        let sink = Amplify.Predictions.convert(speechToText: URL(fileURLWithPath: "file:///path/to/file"))
        .flatMap { speechToTextResult in
            Amplify.Predictions.convert(
                textToTranslate: speechToTextResult.transcription,
                language: .english,
                targetLanguage: .spanish
            )
        }.flatMap { translatedTextResult in
            Amplify.Predictions.convert(textToSpeech: translatedTextResult.text)
        }
        .sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedOperationsFail() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.convertSpeechToText = { _, _ in
            .success(SpeechToTextResult(transcription: "Hello"))
        }

        plugin.responders.convertTextToTranslate = { _, _, _, _ in
            .failure(.unknown("Test", "Test"))
        }

        plugin.responders.convertTextToSpeech = { _, _ in
            .success(TextToSpeechResult(audioData: Data()))
        }

        let sink = Amplify.Predictions.convert(speechToText: URL(fileURLWithPath: "file:///path/to/file"))
        .flatMap { speechToTextResult in
            Amplify.Predictions.convert(
                textToTranslate: speechToTextResult.transcription,
                language: .english,
                targetLanguage: .spanish
            )
        }.flatMap { translatedTextResult in
            Amplify.Predictions.convert(textToSpeech: translatedTextResult.text)
        }
        .sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

}
