//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite

protocol SQLStorageProtocol {
    var diskBytesUsed: Byte { get }
    /// Create SQL table
    /// - Parameter statement: SQL statement to create table
    func createTable(_ statement: String) throws

    /// Executes a SQL statement
    /// - Parameters:
    ///   - statement: SQL statement
    ///   - bindings: Collection of SQL Bindings
    /// - Returns: A Single SQL Statement
    func executeQuery(_ statement: String, _ bindings: [Binding?]) throws -> Statement
}
