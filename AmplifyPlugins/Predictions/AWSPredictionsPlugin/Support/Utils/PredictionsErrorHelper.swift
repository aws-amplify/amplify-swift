//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSRekognition
import AWSTextract
import AWSPolly
import AWSTranslate
import AWSComprehend
import AWSTranscribeStreaming

class PredictionsErrorHelper {

    static func mapHttpResponseCode(statusCode: Int, serviceKey: String) -> PredictionsError? {

        switch statusCode {
        case 200 ..< 300:
            return nil
        case 404:
            return PredictionsError.httpStatus(statusCode, "Please check your request and try again")
        case 400:
            return PredictionsError.httpStatus(statusCode,
                                               """
                                                There are number of reasons for receiving a
                                                400 status code. Please check the service documentation
                                                for the specific service you are hitting.
                                                """)
        case 500:
            return PredictionsError.httpStatus(statusCode,
                                               """
                                                The request processing has failed because of an
                                                unknown error, exception or failure. Please check
                                                aws-amplify github for known issues.
                                                """)
        case 503:
            return PredictionsError.httpStatus(statusCode,
                                               "The request has failed due to a temporary failure of the server.")
        default:
            return PredictionsError.httpStatus(
                statusCode,
                """
                Status code unrecognized, please refer
                to the AWS Service error documentation.
                https://docs.aws.amazon.com/directoryservice/latest/devguide/CommonErrors.html
                """
            )
        }
    }

    // swiftlint:disable cyclomatic_complexity
    static func mapPredictionsServiceError(_ error: NSError) -> PredictionsError {
        let defaultError = PredictionsErrorHelper.getDefaultError(error)

        switch error.domain {
        case AWSServiceErrorDomain:
            let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
            guard let errorType = errorTypeOptional else {
                return defaultError
            }
            return AWSServiceErrorMessage.map(errorType) ?? defaultError
        case AWSRekognitionErrorDomain:
            guard let errorType = AWSRekognitionErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSRekognitionErrorMessage.map(errorType) ?? defaultError
        case AWSPollyErrorDomain:
            guard let errorType = AWSPollyErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSPollyErrorMessage.map(errorType) ?? defaultError
        case AWSTextractErrorDomain:
            guard let errorType = AWSTextractErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSTextractErrorMessage.map(errorType) ?? defaultError
        case AWSComprehendErrorDomain:
            guard let errorType = AWSComprehendErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSComprehendErrorMessage.map(errorType) ?? defaultError
        case AWSTranslateErrorDomain:
            guard let errorType = AWSTranslateErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSTranslateErrorMessage.map(errorType) ?? defaultError
        case AWSTranscribeStreamingErrorDomain:
            guard let errorType = AWSTranscribeStreamingErrorType.init(rawValue: error.code) else {
                return defaultError
            }
            return AWSTranscribeStreamingErrorMessage.map(errorType) ?? defaultError
        case NSURLErrorDomain:
            guard let urlError = error as? URLError else {
                return defaultError
            }
            return mapUrlError(urlError)
        default:
            return defaultError
        }
    }

    static func mapUrlError(_ urlError: URLError) -> PredictionsError {

        switch urlError.code {
        case .cannotFindHost:
            let errorDescription = "The host name for a URL couldn’t be resolved."
            let recoverySuggestion = "Please check if you are reaching the correct host."
            return PredictionsError.network(errorDescription, recoverySuggestion, urlError)
        case .notConnectedToInternet:
            // swiftlint:disable:next line_length
            let errorDescription = "A network resource was requested, but an internet connection hasn’t been established and can’t be established automatically."
            let recoverySuggestion = "Please check your network connectivity status."
            return PredictionsError.network(errorDescription, recoverySuggestion, urlError)
        default:
            return PredictionsError.network(urlError.localizedDescription, "", urlError)
        }
    }

    static func getDefaultError(_ error: NSError) -> PredictionsError {
        let errorMessage = """
        Domain: [\(error.domain)
        Code: [\(error.code)
        LocalizedDescription: [\(error.localizedDescription)
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
        """

        return PredictionsError.unknown(errorMessage, "")
    }
}
