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

    func testAnalyzeDocument_internalServerError() throws {
        assertCatchVariations(
            for: InternalServerError(),
            expecting: .internalServerError,
            label: "internalServerError"
        )
    }

    func testAnalyzeDocument_accessDeniedException() throws {
        assertCatchVariations(
            for: AccessDeniedException(),
            expecting: .accessDenied,
            label: "accessDenied"
        )
    }

    func testAnalyzeDocument_throttlingException() throws {
        assertCatchVariations(
            for: ThrottlingException(),
            expecting: .throttling,
            label: "throttling"
        )
    }
}
