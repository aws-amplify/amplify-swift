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
            language: .usEnglish
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
            .translateText("Hello, world!", from: .english, to: .german)
        )

        XCTAssertEqual(result.text, "Hallo, Welt!")
    }

    var cancellables = Set<AnyCancellable>()
    func testTranslateCombine() -> AnyCancellable {
        Amplify.Publisher.create {
            try await Amplify.Predictions.convert(
                .translateText(
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
    }

    func testConvertTextToSpeech() async throws {
        let result = try await Amplify.Predictions.convert(
            .textToSpeech("Hello, world!"),
            options: .init(voice: .brazPortugueseMaleRicardo)
        )
        XCTAssertFalse(result.audioData.isEmpty)
    }
}
