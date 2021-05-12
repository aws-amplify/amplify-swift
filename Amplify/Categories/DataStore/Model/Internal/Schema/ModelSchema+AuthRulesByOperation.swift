//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Array where Element == AuthRule {
    func filter(modelOperation operation: ModelOperation) -> [Element] {
        filter { $0.operations.contains(operation) }
    }
}
