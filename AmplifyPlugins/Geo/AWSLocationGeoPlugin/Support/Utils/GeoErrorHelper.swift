//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSLocation

class GeoErrorHelper {
    static func getDefaultError(_ error: Error) -> Geo.Error {
        let error = error as NSError
        let errorMessage = """
        Domain: [\(error.domain)
        Code: [\(error.code)
        LocalizedDescription: [\(error.localizedDescription)
        LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
        LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
        """

        return Geo.Error.unknown(errorMessage, "")
    }

    static func mapServiceError(_ error: Error) -> Geo.Error {
        let error = error as NSError
        let defaultError = GeoErrorHelper.getDefaultError(error)

        guard error.domain == AWSServiceErrorDomain else {
            return defaultError
        }

        let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return defaultError
        }

        return GeoErrorHelper.map(errorType) ?? defaultError
    }

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> Geo.Error? {
        switch errorType {
        case .unknown:
            break
        case .requestTimeTooSkewed:
            break
        case .invalidSignatureException:
            break
        case .signatureDoesNotMatch:
            break
        case .requestExpired:
            break
        case .authFailure:
            break
        case .accessDeniedException:
            return Geo.Error.accessDenied("StorageErrorConstants.accessDenied.errorDescription",
                                             "StorageErrorConstants.accessDenied.recoverySuggestion")
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return Geo.Error.accessDenied("StorageErrorConstants.accessDenied.errorDescription",
                                             "StorageErrorConstants.accessDenied.recoverySuggestion")
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return Geo.Error.accessDenied("StorageErrorConstants.accessDenied.errorDescription",
                                             "StorageErrorConstants.accessDenied.recoverySuggestion")
        case .authMissingFailure:
            break
        case .throttling:
            break
        case .throttlingException:
            break
        @unknown default:
            break
        }

        return nil
    }
}
