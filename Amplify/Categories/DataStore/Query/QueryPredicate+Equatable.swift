//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private func isEqual(_ one: QueryPredicate?, to other: QueryPredicate?) -> Bool {
    if one == nil && other == nil {
        return true
    }
    if let one = one as? QueryPredicateOperation, let other = other as? QueryPredicateOperation {
        return one == other
    }

    return false
}
