//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSPredictionsPlugin
import AVFoundation

import Combine

class ConvertBasicIntegrationTests: AWSPredictionsPluginTestBase {
    func testConvertSpeechToText() async throws {
        let testBundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(testBundle.url(forResource: "audio", withExtension: "wav"))

        let options = Predictions.Convert.SpeechToText.Options(
            defaultNetworkPolicy: .auto,
            language: .usEnglish//,
//            pluginOptions: nil
        )

        let result = try await Amplify.Predictions.convert(
            .speechToText(url: url), options: options
        )
        let responses = result.map(\.transcription)
        
        for try await response in responses {
            print("Response in test", response)
        }

        XCTAssertNotNil(result, "Result should contain value")
    }

    func testConvertTranslateText() async throws {
        let result = try await Amplify.Predictions.convert(
            .textToTranslate("Hello, world!", from: .english, to: .german)
        )

        XCTAssertEqual(result.text, "Hallo, Welt!")
    }

    var cancellables = Set<AnyCancellable>()
    func testPublisher() -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Predictions.convert(
                .textToTranslate(
                    "Hello, world!",
                    from: .english,
                    to: .spanish
                )
            )
        }
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                print("Error translating text: \(error)")
            }
        }, receiveValue: { value in
            print("Translated text: \(value.text)")
        })
//        .store(in: &cancellables)
//        try await Task.sleep(for: .seconds(2))
    }

    func testConvertTextToSpeech() async throws {
        let result = try await Amplify.Predictions.convert(
            .textToSpeech("Hello, world!"),
            options: .init(voice: .brazPortugueseMaleRicardo)
        )

        let player = try? AVAudioPlayer(data: result.audioData)
        player?.play()
        try await Task.sleep(for: .seconds(2))
        XCTAssertFalse(result.audioData.isEmpty)
    }
}

//let image = URL(string: "")!
//
//Amplify.Predictions.identify(.text, in: image)
//Amplify.Predictions.identify(.celebrities, in: image)
//Amplify.Predictions.identify(.entities, in: image)
//Amplify.Predictions.identify(.labels(type: .moderation), in: image)
//Amplify.Predictions.identify(.labels(type: .all), in: image)
//
//Amplify.Predictions.identifyText(in: image)
//Amplify.Predictions.identifyCelebrities(in: image)
//Amplify.Predictions.identifyEntities(in: image)
//Amplify.Predictions.identifyModerationLabels(in: image)
//Amplify.Predictions.identifyAllLabels(in: image)
//
//
//let url = URL(string: "")!
//Amplify.Predictions.convert(.speechToText(url: url))
//Amplify.Predictions.convert(.textToTranslate("Hello, world!"), from: .english, to: .german)
//Amplify.Predictions.convert(.textToSpeech("Hello, world!"))
//
//Amplify.Predictions.convertSpeechToText(url: url)
//Amplify.Predictions.translateText("Hello, world!", from: .english, to: .german)
//Amplify.Predictions.convertTextToSpeech("Hello, world!")


// this test only tests online functionality.
// offline functionality cannot be tested through an
// integration test because speech recognition through
// CoreML has to be run on device only.
//    func testConvertSpeechToText() async throws {
//        let testBundle = Bundle(for: type(of: self))
//        guard let url = testBundle.url(forResource: "audio", withExtension: "wav") else {
//            return XCTFail("")
//        }
//
//        let options = PredictionsSpeechToTextRequest.Options(
//            defaultNetworkPolicy: .auto,
//            language: .usEnglish,
//            pluginOptions: nil
//        )
//
//        let result = try await Amplify.Predictions.convert(
//            speechToText: url,
//            options: options,
//            onEvent: {
//                print("EVENT ", $0)
//            }
//        )
//
//        XCTAssertNotNil(result, "Result should contain value")
//    }

//    func testConvertTranslateText_ConfigDefaultLanguages() async throws {
//        let result = try await Amplify.Predictions.convert(
//            textToTranslate: "Hello, world!",
//            language: nil,
//            targetLanguage: nil
//        )
//
//        XCTAssertEqual(result.text, "Hallo, Welt!")
//    }

//    func testConvertTranslateText_CallsiteDefinedLanguages() async throws {
//        let result = try await Amplify.Predictions.convert(
//            textToTranslate: "Hello, world!",
//            language: .usEnglish,
//            targetLanguage: .spanish
//        )
//        XCTAssertEqual(result.text, "¡Hola, mundo!")
//    }

//    func testConvertTextToSpeech() async throws {
//        let result = try await Amplify.Predictions.convert(textToSpeech: "Hello, world!")
////        let player = try AVAudioPlayer(data: result.audioData)
////        player.play()
//        XCTAssertFalse(result.audioData.isEmpty)
//    }
