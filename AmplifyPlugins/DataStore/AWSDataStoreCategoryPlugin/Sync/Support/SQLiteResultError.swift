//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SQLite
import Amplify

/// Checks for specific SQLLite error codes
/// See https://sqlite.org/rescode.html#primary_result_code_list for more details
struct SQLiteResultError {

    /// Constraint Violation, such as foreign key constraint violation, occurs when trying to process a SQL statement
    /// where the insert/update statement is performed for a child object and its parent does not exist.
    /// See https://sqlite.org/rescode.html#constraint for more details
    static func isConstraintViolation(_ dataStoreError: DataStoreError) -> Bool {
        guard case let .invalidOperation(error) = dataStoreError,
              let resultError = error as? Result,
              case .error(_, let code, _) = resultError,
              code == SQLITE_CONSTRAINT else {
            return false
        }

        return true
    }
}
