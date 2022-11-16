//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import SQLite

@testable import InternalAWSPinpoint

class MockSQLiteLocalStorageAdapter: SQLStorageProtocol {
    var diskBytesUsed: Byte = 1
    var statement: String = ""

    func createTable(_ statement: String) throws {
        self.statement = statement
    }

    func executeQuery(_ statement: String, _ bindings: [Binding?]) throws -> Statement {
        fatalError("Not Implemented")
    }
}
