//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import SmithyHTTPAPI

// From an Analytics perspective, a non-retryable error thrown by a PutEvents request
// means that all those events should be immediately pruned from the local database.
//
// Any "transient" error should be retried on the next event submission,
// so only `ClientError.serializationFailed` is considered to be non-retryable.

extension Smithy.ClientError {
    var isRetryable: Bool {
        switch self {
        case .authError:
            return true
        case .dataNotFound:
            return true
        case .invalidValue:
            return true
        case .serializationFailed:
            return false
        case .unknownError:
            return true
        }
    }
}

extension SmithyHTTPAPI.HTTPClientError {
    var isRetryable: Bool {
        switch self {
        case .pathCreationFailed:
            return true
        case .queryItemCreationFailed:
            return true
        }
    }
}
