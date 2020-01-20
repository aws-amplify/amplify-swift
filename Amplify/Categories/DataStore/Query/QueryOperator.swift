//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum QueryOperator {
    case notEqual(_ value: Persistable?)
    case equals(_ value: Persistable?)
    case lessOrEqual(_ value: Persistable)
    case lessThan(_ value: Persistable)
    case greaterOrEqual(_ value: Persistable)
    case greaterThan(_ value: Persistable)
    case contains(_ value: String)
    case between(start: Persistable, end: Persistable)
    case beginsWith(_ value: String)
}
