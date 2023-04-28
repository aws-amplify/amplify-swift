//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPolly
import Amplify
@testable import AWSPredictionsPlugin

final class PollyErrorMappingTestCase: XCTestCase {
    private func assertCatchVariations(
        for sdkError: SynthesizeSpeechOutputError,
        expecting expectedServiceError: PredictionsError.ServiceError,
        label: String
    ) {
        let predictionsError = ServiceErrorMapping.synthesizeSpeech.map(sdkError)
        let unexpected: (Error) -> String = {
            "Expected PredictionsError.service(.\(label), received \($0)"
        }

        // catch variation 1.
        do { throw predictionsError }
        catch PredictionsError.service(expectedServiceError) {}
        catch {
            XCTFail(unexpected(error))
        }

        // catch variation 2.
        do { throw predictionsError }
        catch let error as PredictionsError {
            guard case .service(expectedServiceError) = error else {
                return XCTFail(unexpected(error))
            }
        } catch {
            XCTFail(unexpected(error))
        }

        // catch variation 3.
        do { throw predictionsError }
        catch {
            guard let error = error as? PredictionsError,
                  case .service(expectedServiceError) = error
            else {
                return XCTFail(unexpected(error))
            }
        }
    }

    func testSynthesizeSpeech_invalidSampleRateException() throws {
        assertCatchVariations(
            for: .invalidSampleRateException(.init()),
            expecting: .invalidSampleRate,
            label: "invalidSampleRate"
        )
    }

    func testSynthesizeSpeech_languageNotSupportedException() throws {
        assertCatchVariations(
            for: .languageNotSupportedException(.init()),
            expecting: .unsupportedLanguage,
            label: "unsupportedLanguage"
        )
    }

    func testSynthesizeSpeech_serviceFailureException() throws {
        assertCatchVariations(
            for: .serviceFailureException(.init()),
            expecting: .internalServerError,
            label: "internalServerError"
        )
    }

    func testSynthesizeSpeech_textLengthExceededException() throws {
        assertCatchVariations(
            for: .textLengthExceededException(.init()),
            expecting: .textSizeLimitExceeded,
            label: "textSizeLimitExceeded"
        )
    }
}
