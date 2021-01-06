//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The access level for objects in Storage operations.
/// See https://aws-amplify.github.io/docs/ios/storage#storage-access
public enum StorageAccessLevel: String {

    /// Objects can be read or written by any user without authentication
    case guest

    /// Objects can be viewed by any user without authentication, but only written by the owner
    case protected

    /// Objects can only be read and written by the owner
    case `private`
}
