//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// TODO: Clean this up further
extension APIError {
    // swiftlint:disable cyclomatic_complexity
    init(urlError: URLError, httpURLResponse: HTTPURLResponse? = nil) {
        let errorMessage = """
        LocalizedDescription: [\(urlError.localizedDescription)
        FailureURL: [\(urlError.failureURLString ?? "None")
        """

        var backgroundTaskCancelledReasonMessage: String?
        var networkUnavailableReasonMessage: String?
        if #available(iOS 13.0, *) {
            if let backgroundTaskCancelledReason = urlError.backgroundTaskCancelledReason {
                switch backgroundTaskCancelledReason {
                case .backgroundUpdatesDisabled:
                    backgroundTaskCancelledReasonMessage =
                    "background updates are disabled, background task is cancelled"
                case .insufficientSystemResources:
                    backgroundTaskCancelledReasonMessage =
                    "Background task is cancelled due to insufficient system resources"
                case .userForceQuitApplication:
                    backgroundTaskCancelledReasonMessage =
                    "Background task is cancelled due to user force quit application"
                default: break
                }
            }

            // GetNetworkUnavilableReasonFriendlyMessage
            if let networkUnavailableReason = urlError.networkUnavailableReason {
                switch networkUnavailableReason {
                case .cellular: networkUnavailableReasonMessage = "Network is unavailable on cellular"
                case .expensive: networkUnavailableReasonMessage = "Network is unavailable reason: expensive"
                case .constrained: networkUnavailableReasonMessage = "Network is unavailable reason: constrained"
                default: break
                }
            }
        }
        var urlErrorCodeMessage: String?
        var apiError: APIError?
        switch urlError.code {
        case .unknown: urlErrorCodeMessage = "Unknown"
        case .cancelled: urlErrorCodeMessage = "Cancelled"
        case .badURL: apiError = .invalidURL("URL is bad", "Check the URL", urlError)
        case .timedOut: apiError = .networkError("Timed out. \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .unsupportedURL: apiError = .invalidURL("URL is unsupported", "", urlError)
        case .cannotFindHost: apiError = .networkError("Cannot find host. \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .cannotConnectToHost: apiError = .networkError("Cannot connect to host \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .networkConnectionLost: apiError = .networkError("Network connection lost \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .dnsLookupFailed: apiError = .networkError("DNS lookup failed \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .httpTooManyRedirects: urlErrorCodeMessage = "Too many HTTP redirects."
        case .resourceUnavailable: urlErrorCodeMessage = "Resource is unavailable"
        case .notConnectedToInternet: apiError = .networkError("Not connected to the internet. \(errorMessage)",
            "",
            httpURLResponse,
            urlError)
        case .redirectToNonExistentLocation: urlErrorCodeMessage = "Redirect To NonExistent Location"
        case .badServerResponse: urlErrorCodeMessage = "Bad Server Response"
        case .userCancelledAuthentication: urlErrorCodeMessage = "User Cancelled Authentication"
        case .userAuthenticationRequired: urlErrorCodeMessage = "User Authentication Required"
        case .zeroByteResource: urlErrorCodeMessage = "Zero Byte Resource"
        case .cannotDecodeRawData: urlErrorCodeMessage = "Cannot Decode Raw Data"
        case .cannotDecodeContentData: urlErrorCodeMessage = "Cannot Decode Content Data"
        case .cannotParseResponse: urlErrorCodeMessage = "Cannot Parse Response"
        case .appTransportSecurityRequiresSecureConnection: urlErrorCodeMessage =
            "App Transport Security Requires Secure Connection"
        case .fileDoesNotExist: urlErrorCodeMessage = "File Does Not Exist"
        case .fileIsDirectory: urlErrorCodeMessage = "File Is Directory"
        case .noPermissionsToReadFile: urlErrorCodeMessage = "No Permissions To Read File"
        case .dataLengthExceedsMaximum: urlErrorCodeMessage = "Data Length Exceeds Maximum"
        case .secureConnectionFailed: urlErrorCodeMessage = "Secure Connection Failed"
        case .serverCertificateHasBadDate: urlErrorCodeMessage = "Server Certificate Has Bad Date"
        case .serverCertificateUntrusted: urlErrorCodeMessage = "Server Certificate Untrusted"
        case .serverCertificateHasUnknownRoot: urlErrorCodeMessage = "Server Certificate Has Unknown Root"
        case .serverCertificateNotYetValid: urlErrorCodeMessage = "Server Certificate Not Yet Valid"
        case .clientCertificateRejected: urlErrorCodeMessage = "Client Certificate Rejected"
        case .clientCertificateRequired: urlErrorCodeMessage = "Client Certificate Required"
        case .cannotLoadFromNetwork: urlErrorCodeMessage = "Cannot Load From Network"
        case .cannotCreateFile: urlErrorCodeMessage = "Cannot Create File"
        case .cannotOpenFile: urlErrorCodeMessage = "Cannot Open File"
        case .cannotCloseFile: urlErrorCodeMessage = "Cannot Close File"
        case .cannotWriteToFile: urlErrorCodeMessage = "Cannot Write To File"
        case .cannotRemoveFile: urlErrorCodeMessage = "Cannot Remove File"
        case .cannotMoveFile: urlErrorCodeMessage = "Cannot Move File"
        case .downloadDecodingFailedMidStream: urlErrorCodeMessage = "Download Decoding Failed Mid Stream"
        case .downloadDecodingFailedToComplete: urlErrorCodeMessage = "Download Decoding Failed To Complete"
        case .internationalRoamingOff: urlErrorCodeMessage = "International Roaming Off"
        case .callIsActive: urlErrorCodeMessage = "Call Is Active"
        case .dataNotAllowed: urlErrorCodeMessage = "Data Not Allowed"
        case .requestBodyStreamExhausted: urlErrorCodeMessage = "Request Body Stream Exhausted"
        case .backgroundSessionRequiresSharedContainer: urlErrorCodeMessage =
            "Background Session Requires Shared Container"
        case .backgroundSessionInUseByAnotherProcess: urlErrorCodeMessage =
            "Background Session In Use By Another Process"
        case .backgroundSessionWasDisconnected: urlErrorCodeMessage = "Background Session Was Disconnected"
        default:
            apiError = .urlError("The operation for this request failed.",
                                 """
                The operation for the request shown below failed with the following message: \
                \(urlError.localizedDescription).

                Inspect this error's `.error` property for more information about the urlError.
                If it made it to the service, check the `HTTPURLResponse`
                """,
                urlError,
                httpURLResponse)
        }

        if let apiError = apiError {
            self = apiError
        } else {
            self = .urlError("""
                This request failed with reason: \(urlErrorCodeMessage ?? "")).
                \(backgroundTaskCancelledReasonMessage ?? ""))
                \(networkUnavailableReasonMessage ?? "")
                """,
                """
                The operation for the request shown below failed with the following message: \
                \(errorMessage).

                Inspect this error's `.error` property for more information about the urlError.
                If it made it to the service, check the `HTTPURLResponse`
                """,
                urlError,
                httpURLResponse)
        }
    }
}
