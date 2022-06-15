//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors interfacing with local storage
enum LocalStorageError: Error {
    case missingConnection
    case invalidStorage(path: String, Error? = nil)
    case invalidOperation(causedBy: Error? = nil)
}
