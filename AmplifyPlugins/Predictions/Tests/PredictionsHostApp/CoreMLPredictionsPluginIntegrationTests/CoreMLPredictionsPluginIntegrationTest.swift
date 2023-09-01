//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import XCTest
import AVFoundation

class CoreMLPredictionsPluginIntegrationTest: AWSPredictionsPluginTestBase {

    func testIdentify() async throws {
        let testBundle = Bundle(for: type(of: self))
        let url = try XCTUnwrap(testBundle.url(forResource: "people", withExtension: "jpg"))

        let result: Predictions.Identify.Labels.Result = try await Amplify.Predictions.identify(
            .labels(type: .all),
            in: url
        )

        XCTAssertEqual(result.labels.count, 0, String(describing: result))
        XCTAssertNil(result.unsafeContent, String(describing: result))
    }

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

        do {
            for try await response in responses {
                XCTFail("Expecting failure but got: \(response)")
            }
        } catch let error as NSError {
            XCTAssertEqual(error.code, 201)
            XCTAssertEqual(error.localizedDescription, "Siri and Dictation are disabled")
        }
    }
}
