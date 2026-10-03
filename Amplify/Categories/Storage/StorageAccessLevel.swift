//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The access level for objects in Storage operations.
/// See https://aws-amplify.github.io/docs/ios/storage#storage-access
///
/// - Tag: StorageAccessLevel
@available(*, deprecated, message: "Use `path` in Storage API instead of `Options`")
public enum StorageAccessLevel: String, Sendable {

    /// Objects can be read or written by any user without authentication
    ///
    /// - Tag: StorageAccessLevel.guest
    case guest

    /// Objects can be viewed by any user without authentication, but only written by the owner
    ///
    /// - Tag: StorageAccessLevel.protected
    case protected

    /// Objects can only be read and written by the owner
    ///
    /// - Tag: StorageAccessLevel.private
    case `private`

    // Bridges live in the type body: members don't inherit the type's deprecation.
    package init(_ legacy: LegacyStorageAccessLevel) {
        switch legacy {
        case .guest:
            self = .guest
        case .protected:
            self = .protected
        case .private:
            self = .private
        }
    }

    package var legacyValue: LegacyStorageAccessLevel {
        switch self {
        case .guest:
            return .guest
        case .protected:
            return .protected
        case .private:
            return .private
        }
    }
}

/// Non-deprecated mirror of `StorageAccessLevel`, used to carry legacy values without warnings.
package enum LegacyStorageAccessLevel: String, Sendable {
    case guest
    case protected
    case `private`
}
