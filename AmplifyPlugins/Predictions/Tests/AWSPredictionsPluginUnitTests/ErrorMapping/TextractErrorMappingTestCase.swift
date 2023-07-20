//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSTextract
import Amplify
@testable import AWSPredictionsPlugin

final class TextractErrorMappingTestCase: XCTestCase {
    private func assertCatchVariations(
        for sdkError: AnalyzeDocumentOutputError,
        expecting expectedServiceError: PredictionsError.ServiceError,
        label: String
    ) {
        let predictionsError = ServiceErrorMapping.analyzeDocument.map(sdkError)
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

    func testAnalyzeDocument_internalServerError() throws {
        assertCatchVariations(
            for: .internalServerError(.init()),
            expecting: .internalServerError,
            label: "internalServerError"
        )
    }

    func testAnalyzeDocument_accessDeniedException() throws {
        assertCatchVariations(
            for: .accessDeniedException(.init()),
            expecting: .accessDenied,
            label: "accessDenied"
        )
    }

    func testAnalyzeDocument_throttlingException() throws {
        assertCatchVariations(
            for: .throttlingException(.init()),
            expecting: .throttling,
            label: "throttling"
        )
    }
}
