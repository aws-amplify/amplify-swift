//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol that represents a Storage bucket.
///
/// - Tag: StorageBucket
public protocol StorageBucket { }

/// Represents information about a Storage bucket
///
/// - Tag: BucketInfo
public struct BucketInfo: Hashable {
    /// The name of the bucket
    /// - Tag: BucketInfo.bucketName
    public let bucketName: String

    /// The region of the bucket
    /// - Tag: BucketInfo.region
    public let region: String

    public init(bucketName: String, region: String) {
        self.bucketName = bucketName
        self.region = region
    }
}

public extension StorageBucket where Self == OutputsStorageBucket {
    /// References a `StorageBucket` in the AmplifyOutputs file using the given name.
    ///
    /// - Parameter name: The name of the bucket
    static func fromOutputs(name: String) -> Self {
        return OutputsStorageBucket(name: name)
    }
}

public extension StorageBucket where Self == ResolvedStorageBucket {
    /// References a `StorageBucket` using the data from the given `BucketInfo`.
    ///
    /// - Parameter bucketInfo: A `BucketInfo` instance
    static func fromBucketInfo(_ bucketInfo: BucketInfo) -> Self {
        return ResolvedStorageBucket(bucketInfo: bucketInfo)
    }
}

/// Conforms to `StorageBucket`. Represents a Storage Bucket defined by a name in the AmplifyOutputs file.
///
/// - Tag: OutputsStorageBucket
public struct OutputsStorageBucket: StorageBucket {
    public let name: String
}

/// Conforms to `StorageBucket`. Represents a Storage Bucket defined by a name and a region defined in `BucketInfo`.
///
/// - Tag: ResolvedStorageBucket
public struct ResolvedStorageBucket: StorageBucket {
    public let bucketInfo: BucketInfo
}
