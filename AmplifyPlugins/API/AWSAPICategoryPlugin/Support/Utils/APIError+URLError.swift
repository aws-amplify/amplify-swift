//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension APIError {
    // swiftlint:disable cyclomatic_complexity
    init(urlError: URLError, httpURLResponse: HTTPURLResponse? = nil) {
        // Some default information
        let errorMessage = """
            LocalizedDescription: [\(urlError.localizedDescription)
            failureURL: [\(urlError.failureURLString ?? "None")
            """

        var friendlyErrorMessage = ""
        if #available(iOS 13.0, *) {
            if let backgroundTaskCancelledReason = urlError.backgroundTaskCancelledReason {
                switch backgroundTaskCancelledReason {
                case .backgroundUpdatesDisabled:
                    friendlyErrorMessage = "backgroundUpdatesDisabled"
                case .insufficientSystemResources:
                    friendlyErrorMessage = "insufficientSystemResources"
                case .userForceQuitApplication:
                    friendlyErrorMessage = "userForceQuitApplication"
                default: break
                }
            }

            // GetNetworkUnavilableReasonFriendlyMessage
            if let networkUnavailableReason = urlError.networkUnavailableReason {
                switch networkUnavailableReason {
                case .cellular: friendlyErrorMessage = "Network unavailable reason: cellular"
                case .expensive: friendlyErrorMessage = "Network unavailable reason: expensive"
                case .constrained: friendlyErrorMessage = "Network unavailable reason: constrained"
                default: break
                }
            }
        }
        var apiError: APIError?
        switch urlError.code {
        case .unknown: friendlyErrorMessage = "Unknown"
        case .cancelled: friendlyErrorMessage = "Cancelled"
        case .badURL: friendlyErrorMessage = "BadURL"
            apiError = .invalidURL("URL is bad", "", urlError)
        case .timedOut:
            apiError = .networkError("Cannot find host. \(errorMessage)",
                "",
                httpURLResponse,
                urlError)
        case .unsupportedURL:
            apiError = .invalidURL("URL is unsupported", "", urlError)
        case .cannotFindHost:
            apiError = .networkError("Cannot find host. \(errorMessage)",
                "",
                httpURLResponse,
                urlError)
        case .cannotConnectToHost:
            apiError = .networkError("Cannot connect to host \(errorMessage)",
                "",
                httpURLResponse,
                urlError)
        case .networkConnectionLost:
            apiError = .networkError("Network connection lost \(errorMessage)",
                "",
                httpURLResponse,
                urlError)
        case .dnsLookupFailed:
            apiError = .networkError("DNS lookup failed \(errorMessage)",
                "",
                                 httpURLResponse,
                                 urlError)
        case .httpTooManyRedirects: friendlyErrorMessage = "Unknown"
        case .resourceUnavailable: friendlyErrorMessage = "Unknown"
        case .notConnectedToInternet:
            apiError = .networkError("Not connected to the internet \(errorMessage)",
                                 "",
                                 httpURLResponse,
                                 urlError)
        case .redirectToNonExistentLocation: friendlyErrorMessage = "redirectToNonExistentLocation"
        case .badServerResponse: friendlyErrorMessage = "badServerResponse"
        case .userCancelledAuthentication: friendlyErrorMessage = "userCancelledAuthentication"
        case .userAuthenticationRequired: friendlyErrorMessage = "userAuthenticationRequired"
        case .zeroByteResource: friendlyErrorMessage = "zeroByteResource"
        case .cannotDecodeRawData: friendlyErrorMessage = "cannotDecodeRawData"
        case .cannotDecodeContentData: friendlyErrorMessage = "cannotDecodeContentData"
        case .cannotParseResponse: friendlyErrorMessage = "cannotParseResponse"
        case .appTransportSecurityRequiresSecureConnection: friendlyErrorMessage = "appTransportSecurityRequiresSecureConnection"
        case .fileDoesNotExist: friendlyErrorMessage = "fileDoesNotExist"
        case .fileIsDirectory: friendlyErrorMessage = "fileIsDirectory"
        case .noPermissionsToReadFile: friendlyErrorMessage = "noPermissionsToReadFile"
        case .dataLengthExceedsMaximum: friendlyErrorMessage = "dataLengthExceedsMaximum"
        case .secureConnectionFailed: friendlyErrorMessage = "secureConnectionFailed"
        case .serverCertificateHasBadDate: friendlyErrorMessage = "serverCertificateHasBadDate"
        case .serverCertificateUntrusted: friendlyErrorMessage = "serverCertificateUntrusted"
        case .serverCertificateHasUnknownRoot: friendlyErrorMessage = "serverCertificateHasUnknownRoot"
        case .serverCertificateNotYetValid: friendlyErrorMessage = "serverCertificateNotYetValid"
        case .clientCertificateRejected: friendlyErrorMessage = "clientCertificateRejected"
        case .clientCertificateRequired: friendlyErrorMessage = "clientCertificateRequired"
        case .cannotLoadFromNetwork: friendlyErrorMessage = "cannotLoadFromNetwork"
        case .cannotCreateFile: friendlyErrorMessage = "cannotCreateFile"
        case .cannotOpenFile: friendlyErrorMessage = "cannotOpenFile"
        case .cannotCloseFile: friendlyErrorMessage = "cannotCloseFile"
        case .cannotWriteToFile: friendlyErrorMessage = "cannotWriteToFile"
        case .cannotRemoveFile: friendlyErrorMessage = "cannotRemoveFile"
        case .cannotMoveFile: friendlyErrorMessage = "cannotMoveFile"
        case .downloadDecodingFailedMidStream: friendlyErrorMessage = "downloadDecodingFailedMidStream"
        case .downloadDecodingFailedToComplete: friendlyErrorMessage = "downloadDecodingFailedToComplete"
        case .internationalRoamingOff: friendlyErrorMessage = "internationalRoamingOff"
        case .callIsActive: friendlyErrorMessage = "callIsActive"
        case .dataNotAllowed: friendlyErrorMessage = "dataNotAllowed"
        case .requestBodyStreamExhausted: friendlyErrorMessage = "requestBodyStreamExhausted"
        case .backgroundSessionRequiresSharedContainer: friendlyErrorMessage = "backgroundSessionRequiresSharedContainer"
        case .backgroundSessionInUseByAnotherProcess: friendlyErrorMessage = "backgroundSessionInUseByAnotherProcess"
        case .backgroundSessionWasDisconnected: friendlyErrorMessage = "backgroundSessionWasDisconnected"
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
            self = .urlError("This request failed with \(friendlyErrorMessage).",
                """
                The operation for the request shown below failed with the following message: \
                \(urlError.localizedDescription).

                Inspect this error's `.error` property for more information about the urlError.
                If it made it to the service, check the `HTTPURLResponse`
                """,
                urlError,
                httpURLResponse)
        }
    }
}
