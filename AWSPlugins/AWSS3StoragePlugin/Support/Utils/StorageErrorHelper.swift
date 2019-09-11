//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify
import AWSS3

class StorageErrorHelper {

//    static func mapHttpResponse() -> StorageErrorString? {
//
//    }

    static func map(_ error: NSError) -> StorageErrorString {
        // default error handling on NSError
        let innerMessage = StorageErrorHelper.getInnerMessage(error)
        let errorDescription = StorageErrorHelper.getErrorDescription(innerMessage: innerMessage)

        let storageErrorString = (errorDescription: errorDescription, recoverySuggestion: "RecoverySuggestion")

        // Ensure it is the right domain
        guard error.domain == AWSServiceErrorDomain else {
            return storageErrorString
        }

        // Try to get specific erorr
        let errorTypeOptional = AWSServiceErrorType.init(rawValue: error.code)
        guard let errorType = errorTypeOptional else {
            return storageErrorString
        }

        // Extract specific error details and map to Amplify error
        let storageListErrorOptional = StorageErrorHelper.map(errorType)

        return storageListErrorOptional ?? storageErrorString
    }

    static func mapTransferUtilityError(_ error: NSError) -> StorageErrorString {
        // default error handling on NSError
        let innerMessage = StorageErrorHelper.getInnerMessage(error)
        let errorDescription = StorageErrorHelper.getErrorDescription(innerMessage: innerMessage)
        let storageErrorString = (errorDescription: errorDescription, recoverySuggestion: "RecoverySuggestion")

        // Ensure it is a transferUtilityErrorDomain - maybe not needed
        guard error.domain == AWSS3TransferUtilityErrorDomain else {
            return storageErrorString
        }

        // Try to get specific error
        guard let errorType = AWSS3TransferUtilityErrorType.init(rawValue: error.code) else {
            return storageErrorString
        }

        // Extract specific error details and map to Amplify error
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
            return StorageErrorConstants.missingFile
        default:
            break
        }

        return storageErrorString
    }

    static func getInnerMessage(_ error: NSError) -> String {
        return error.localizedDescription // TODO: generate useful inner message
    }

    static func getErrorDescription(innerMessage: String) -> String {
        return "The error is [" + innerMessage + "]"
    }

    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> StorageErrorString? {
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
            return StorageErrorConstants.accessDenied
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return StorageErrorConstants.accessDenied
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return StorageErrorConstants.accessDenied
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
