//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSMobileClient
import Amplify

public class StorageErrorHelper {
    public static func getInnerMessage(_ error: NSError) -> String {
        return error.localizedDescription // TODO: generate useful inner message
    }

    public static func getErrorDescription(innerMessage: String) -> String {
        return "The error is [" + innerMessage + "]"
    }

    // TODO remove or keep swiftlint exception
    // swiftlint:disable cyclomatic_complexity
    static func map(_ errorType: AWSServiceErrorType) -> StorageListError? {
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
            return StorageListError.accessDenied(StorageErrorConstants.AccessDenied.ErrorDescription,
                                                 StorageErrorConstants.AccessDenied.RecoverySuggestion)
        case .unrecognizedClientException:
            break
        case .incompleteSignature:
            break
        case .invalidClientTokenId:
            break
        case .missingAuthenticationToken:
            break
        case .accessDenied:
            return StorageListError.accessDenied(StorageErrorConstants.AccessDenied.ErrorDescription,
                                                 StorageErrorConstants.AccessDenied.RecoverySuggestion)
            break
        case .expiredToken:
            break
        case .invalidAccessKeyId:
            break
        case .invalidToken:
            break
        case .tokenRefreshRequired:
            break
        case .accessFailure:
            return StorageListError.accessDenied(StorageErrorConstants.AccessDenied.ErrorDescription,
                                                 StorageErrorConstants.AccessDenied.RecoverySuggestion)
            break
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
