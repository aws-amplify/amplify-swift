//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// A sub-protocol of `DataStoreStatement` that represents a SQL statement.
///
/// SQL statements include: `create table`, `insert`, `update`, `delete` and `select`.
protocol SQLStatement: DataStoreStatement where Variables == [Binding?] {}

/// An useful extension to add a default empty array to `SQLStatement.variables` to
/// concrete types conforming to `SQLStatement`.
extension SQLStatement {

    var variables: [Binding?] {
        return []
    }
}
