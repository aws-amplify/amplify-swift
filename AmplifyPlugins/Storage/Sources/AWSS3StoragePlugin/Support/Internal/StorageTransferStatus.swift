//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum StorageTransferStatus: Int {
    case unknown = 0
    case inProgress = 1
    case paused = 2
    case completed = 3
    case waiting = 4
    case error = 5
    case cancelled = 6
}
