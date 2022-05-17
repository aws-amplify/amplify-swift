//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors interfacing with local storage
public enum LocalStorageError: Error {
    case nilSQLiteConnection
    case invalidDatabase(path: String, Error? = nil)
    case invalidOperation(causedBy: Error? = nil)
}
