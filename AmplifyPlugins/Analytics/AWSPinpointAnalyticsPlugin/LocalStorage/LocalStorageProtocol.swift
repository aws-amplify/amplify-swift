//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

protocol LocalStorageProtocol {
    /// Executes a SQL statement
    /// - Parameters:
    ///   - statement: SQL statement
    ///   - bindings: Collection of SQL Bindings
    /// - Returns: A Single SQL Statement
    func executeSqlQuery(_ statement: String, _ bindings: [Binding?]) throws -> Statement
}
