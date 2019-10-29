//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum QueryPredicate {
    case notEqual(_ value: PersistentValue?)
    case equals(_ value: PersistentValue?)
    case lessOrEqual(_ value: PersistentValue)
    case lessThan(_ value: PersistentValue)
    case greaterOrEqual(_ value: PersistentValue)
    case greaterThan(_ value: PersistentValue)
    case contains(_ value: String)
    case between(start: PersistentValue, end: PersistentValue)
    case beginsWith(_ value: String)
}
