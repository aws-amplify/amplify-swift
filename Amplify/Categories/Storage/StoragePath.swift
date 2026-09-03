//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `@Sendable` because resolvers are invoked from the storage plugins async work.
public typealias IdentityIDPathResolver = @Sendable (String) -> String

/// Protocol that provides a closure to resolve the storage path.
///
/// - Tag: StoragePath
/// - Note: `Sendable` because paths are stored on storage requests, which cross task boundaries.
public protocol StoragePath: Sendable {
    associatedtype Input
    var resolve: (Input) -> String { get }
}

public extension StoragePath where Self == StringStoragePath {
    static func fromString(_ path: String) -> Self {
        return StringStoragePath(resolve: { _ in return path })
    }
}

public extension StoragePath where Self == IdentityIDStoragePath {
    static func fromIdentityID(_ identityIdPathResolver: @escaping IdentityIDPathResolver) -> Self {
        return IdentityIDStoragePath(resolve: identityIdPathResolver)
    }
}

/// Conforms to StoragePath protocol.  Provides a storage path based on a string storage path.
///
/// - Tag: StringStoragePath
public struct StringStoragePath: StoragePath {
    public let resolve: @Sendable (String) -> String
}

/// Conforms to StoragePath protocol.
/// Provides a storage path constructed from an unique identity identifer.
///
/// - Tag: IdentityStoragePath
public struct IdentityIDStoragePath: StoragePath {
    public let resolve: IdentityIDPathResolver
}
