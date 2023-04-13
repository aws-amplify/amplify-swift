//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// TODO: Transcribe

//import AWSTranscribeStreaming
//import Amplify
//
//typealias AWSTranscribeErrorString = (errorDescription: ErrorDescription, recoverySuggestion: RecoverySuggestion)
//
//struct AWSTranscribeStreamingErrorMessage {
//
//    static let unknown: AWSTranscribeErrorString = ("Transcribe failed for an unknown reason",
//        """
//        For a list of commone errors of why Transcribe may have failed,
//        check here:
//        https://docs.aws.amazon.com/transcribe/latest/dg/CommonErrors.html
//        """)
//
//    static let conflict: AWSTranscribeErrorString = (
//        "The WebSocket upgrade request was signed with an incorrect access key or secret key.",
//        "Make sure that you are correctly creating the access key and try your request again.")
//
//    static let badRequest: AWSTranscribeErrorString = (
//        "There was a client error when the stream was created, or an error occurred while streaming data.",
//        "Make sure that your client is ready to accept data and try your request again.")
//
//    static let internalFailure: AWSTranscribeErrorString = (
//        "Amazon Transcribe had a problem during the handshake with the client.",
//        "Please try your request again.")
//
//    static let limitExceeded: AWSTranscribeErrorString = ("The client exceeded the concurrent stream limit.",
//        """
//        Reduce the number of streams that you are transcribing.
//        Check the limits here:
//        https://docs.aws.amazon.com/general/latest/gr/aws_service_limits.html#limits-amazon-transcribe
//        """)
//
//    static func map(_ errorType: AWSTranscribeStreamingErrorType) -> PredictionsError? {
//        switch errorType {
//        case .badRequest:
//            return PredictionsError.service(badRequest.errorDescription, badRequest.recoverySuggestion)
//        case .conflict:
//            return PredictionsError.service(conflict.errorDescription, conflict.recoverySuggestion)
//        case .internalFailure:
//            return PredictionsError.service(internalFailure.errorDescription, internalFailure.recoverySuggestion)
//        case .limitExceeded:
//            return PredictionsError.service(limitExceeded.errorDescription, limitExceeded.recoverySuggestion)
//        case .unknown:
//            return PredictionsError.service(unknown.errorDescription, unknown.recoverySuggestion)
//        default:
//            return PredictionsError.service(unknown.errorDescription, unknown.recoverySuggestion)
//        }
//    }
//}
