

import Foundation

public typealias StoragePathResolver = (String) -> String

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

public struct StringStoragePath: StoragePath {
    public let pathResolver: StoragePathResolver
}

public struct IdentityIdStoragePath: StoragePath {
    public let pathResolver: StoragePathResolver
}

