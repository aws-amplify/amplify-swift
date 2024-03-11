//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias StoragePathResolver = (String) -> String

/// Protocol that provides a closure to resolve the storage path.
///
/// - Tag: StoragePath
public protocol StoragePath {
    var pathResolver: StoragePathResolver { get }
}

public extension StoragePath where Self == StringStoragePath {
    static func fromString(_ path: String) -> Self {
        return StringStoragePath(pathResolver: { _ in return path })
    }
}

public extension StoragePath where Self == IdentityIdStoragePath  {
    static func fromIdentityId(_ identityIdPathResolver: @escaping StoragePathResolver) -> Self {
        return IdentityIdStoragePath(pathResolver: identityIdPathResolver)
    }
}

/// Conforms to StoragePath protocol.  Provides a storage path based on a string storage path.
///
/// - Tag: StringStoragePath
public struct StringStoragePath: StoragePath {
    public let pathResolver: StoragePathResolver
}

/// Conforms to StoragePath protocol.
/// Provides a storage path constructed from an unique identity identifer.
///
/// - Tag: IdentityStoragePath
public struct IdentityIdStoragePath: StoragePath {
    public let pathResolver: StoragePathResolver
}

