//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/*
import Foundation
import Amplify
import AWSS3

class StorageErrorHelper {

    static func mapHttpResponseCode(statusCode: Int, serviceKey: String) -> StorageError? {
        if statusCode >= 200 && statusCode <= 299 {
            return nil
        }

        if statusCode == 404 {
            return StorageError.keyNotFound(serviceKey,
                                            "Received HTTP Response status code 404 NotFound",
                                            "Make sure the key exists before trying to download it.")
        }

        return StorageError.httpStatusError(statusCode, "")
    }

    static func mapServiceError(_ error: NSError) -> StorageError {
        let defaultError = StorageErrorHelper.getDefaultError(error)

        guard error.domain == AWSServiceErrorDomain else {
            return defaultError
        }

        let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return defaultError
        }

        return StorageErrorHelper.map(errorType) ?? defaultError
    }

    static func mapTransferUtilityError(_ error: NSError) -> StorageError {
        let defaultError = StorageErrorHelper.getDefaultError(error)

        guard error.domain == AWSS3TransferUtilityErrorDomain else {
            return defaultError
        }

        guard let errorType = AWSS3TransferUtilityErrorType.init(rawValue: error.code) else {
            return defaultError
        }

        return StorageErrorHelper.map(errorType) ?? defaultError
    }

    static func getDefaultError(_ error: NSError) -> StorageError {
        let errorMessage = """
                           Domain: [\(error.domain)
                           Code: [\(error.code)
                           LocalizedDescription: [\(error.localizedDescription)
                           LocalizedFailureReason: [\(error.localizedFailureReason ?? "")
                           LocalizedRecoverySuggestion: [\(error.localizedRecoverySuggestion ?? "")
                           """

        return StorageError.unknown(errorMessage)
    }

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> StorageError? {
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
            return StorageError.accessDenied(StorageErrorConstants.accessDenied.errorDescription,
                                             StorageErrorConstants.accessDenied.recoverySuggestion)
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return StorageError.accessDenied(StorageErrorConstants.accessDenied.errorDescription,
                                             StorageErrorConstants.accessDenied.recoverySuggestion)
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return StorageError.accessDenied(StorageErrorConstants.accessDenied.errorDescription,
                                             StorageErrorConstants.accessDenied.recoverySuggestion)
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

    static func map(_ errorType: AWSS3TransferUtilityErrorType) -> StorageError? {
        switch errorType {
        case .clientError:
            break
        case .unknown:
            break
        case .redirection:
            break
        case .serverError:
            break
        case .localFileNotFound:
            return StorageError.localFileNotFound(StorageErrorConstants.localFileNotFound.errorDescription,
                                                  StorageErrorConstants.localFileNotFound.recoverySuggestion)
        default:
            break
        }

        return nil
    }
}
*/
