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
        for sdkError: Error,
        expecting expectedServiceError: PredictionsError.ServiceError,
        label: String
    ) {
        let unexpected: (Error) -> String = {
            "Expected PredictionsError.service(.\(label), received \($0)"
        }


        // catch variation 1.
        do { throw sdkError }
        catch let error as PredictionsErrorConvertible {
            guard case .service(expectedServiceError) = error.predictionsError else {
                return XCTFail(unexpected(error.predictionsError))
            }
        }
        catch {
            XCTFail(unexpected(error))
        }

        // catch variation 2.
        do { throw sdkError }
        catch let error as PredictionsErrorConvertible {
            guard case .service(expectedServiceError) = error.predictionsError else {
                return XCTFail(unexpected(error.predictionsError))
            }
        } catch {
            XCTFail(unexpected(error))
        }

        // catch variation 3.
        do { throw sdkError }
        catch {
            guard let error = error as? PredictionsErrorConvertible,
                  case .service(expectedServiceError) = error.predictionsError
            else {
                return XCTFail(unexpected(error))
            }
        }
    }

    func testSynthesizeSpeech_invalidSampleRateException() throws {
        assertCatchVariations(
            for: InvalidSampleRateException(),
            expecting: .invalidSampleRate,
            label: "invalidSampleRate"
        )
    }

    func testSynthesizeSpeech_languageNotSupportedException() throws {
        assertCatchVariations(
            for: LanguageNotSupportedException(),
            expecting: .unsupportedLanguage,
            label: "unsupportedLanguage"
        )
    }

    func testSynthesizeSpeech_serviceFailureException() throws {
        assertCatchVariations(
            for: ServiceFailureException(),
            expecting: .internalServerError,
            label: "internalServerError"
        )
    }

    func testSynthesizeSpeech_textLengthExceededException() throws {
        assertCatchVariations(
            for: TextLengthExceededException(),
            expecting: .textSizeLimitExceeded,
            label: "textSizeLimitExceeded"
        )
    }
}
