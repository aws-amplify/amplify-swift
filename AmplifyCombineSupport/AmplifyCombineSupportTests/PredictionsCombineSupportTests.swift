//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class PredictionsCombineSupportTests: XCTestCase {

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

    func testConvertSpeechToTextSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.convertSpeechToText = { _, _ in
            .success(SpeechToTextResult(transcription: "Hello"))
        }
        _ = Amplify.Predictions.convert(speechToText: URL(fileURLWithPath: "file:///path/to/file"))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testConvertSpeechToTextFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.convertSpeechToText = { _, _ in
            .failure(.unknown("Test", "Test"))
        }
        _ = Amplify.Predictions.convert(speechToText: URL(fileURLWithPath: "file:///path/to/file"))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testConvertTextToSpeechSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.convertTextToSpeech = { _, _ in
            .success(TextToSpeechResult(audioData: Data()))
        }
        _ = Amplify.Predictions.convert(textToSpeech: "Hello")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testConvertTextToSpeechFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.convertTextToSpeech = { _, _ in
            .failure(.unknown("Test", "Test"))
        }
        _ = Amplify.Predictions.convert(textToSpeech: "Hello")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testConvertTextToTranslateSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.convertTextToTranslate = { _, _, _, _ in
            .success(TranslateTextResult(text: "hola", targetLanguage: .spanish))
        }
        _ = Amplify.Predictions.convert(
            textToTranslate: "hello",
            language: .english,
            targetLanguage: .spanish
        ).sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
    }

    func testConvertTextToTranslateFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.convertTextToTranslate = { _, _, _, _ in
            .failure(.unknown("Test", "Test"))
        }
        _ = Amplify.Predictions.convert(
            textToTranslate: "hello",
            language: .english,
            targetLanguage: .spanish
        ).sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
    }

    func testIdentifySucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.identify = { _, _, _ in
            .success(MockIdentifyResult())
        }
        _ = Amplify.Predictions.identify(
            type: .detectCelebrity,
            image: URL(fileURLWithPath: "file:///path/to/file")
        ).sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
    }

    func testIdentifyFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.identify = { _, _, _ in
            .failure(.unknown("Test", "Test"))
        }
        _ = Amplify.Predictions.identify(
            type: .detectCelebrity,
            image: URL(fileURLWithPath: "file:///path/to/file")
        ).sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
    }

    func testInterpretSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.interpret = { _, _ in
            .success(
                InterpretResult(
                    keyPhrases: nil,
                    sentiment: nil,
                    entities: nil,
                    language: nil,
                    syntax: nil
                )
            )
        }
        _ = Amplify.Predictions.interpret(text: "Hello")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testInterpretFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.interpret = { _, _ in
            .failure(.unknown("Test", "Test"))
        }
        _ = Amplify.Predictions.interpret(text: "Hello")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

}

private struct MockIdentifyResult: IdentifyResult { }
