//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation

extension ClientError {
    // TODO: Should some of these really be retried?
    var isRetryable: Bool {
        switch self {
        case .authError:
            return true
        case .dataNotFound:
            return true
        case .pathCreationFailed:
            return true
        case .queryItemCreationFailed:
            return true
        case .serializationFailed:
            return false
        case .unknownError:
            return true
        }
    }
}
