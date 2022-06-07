//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import ClientRuntime
import Foundation

extension SdkError {
    var isRetryable: Bool {
        switch self {
        case .service(let error, _):
            return (error as? PutEventsOutputError)?.isRetryable == true
        case .client(let error, _):
            return error.isRetryable
        default:
            return true
        }
    }
}

extension ClientError {
    var isRetryable: Bool {
        switch self {
        case .authError(_):
            return true
        case .crtError(_):
            return true
        case .dataNotFound(_):
            return true
        case .deserializationFailed(_):
            return false
        case .networkError(_):
            return true
        case .pathCreationFailed(_):
            return true
        case .retryError(_):
            return true
        case .serializationFailed(_):
            return false
        case .unknownError(_):
            return true
        }
    }
}

extension PutEventsOutputError {
    var isRetryable: Bool {
        switch self {
        case .badRequestException(let exception):
            return exception._retryable
        case .forbiddenException(let exception):
            return exception._retryable
        case .internalServerErrorException(let exception):
            return exception._retryable
        case .methodNotAllowedException(let exception):
            return exception._retryable
        case .notFoundException(let exception):
            return exception._retryable
        case .payloadTooLargeException(let exception):
            return exception._retryable
        case .tooManyRequestsException(let exception):
            return exception._retryable
        case .unknown(let exception):
            return exception._retryable
        }
    }
}
