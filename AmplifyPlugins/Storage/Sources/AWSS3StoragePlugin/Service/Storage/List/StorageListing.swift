//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Amplify
import Foundation

/// Encapsulation of an initial call to
/// [S3ClientProtocol.listObjectsV2](x-source-tag://S3ClientProtocol.listObjectsV2) that
/// is used to produce a [StorageListResult](x-source-tag://StorageListResult).
///
/// - Tag: StorageListing
struct StorageListing {

    private let client: S3ClientProtocol

    private let prefix: String

    private let input: ListObjectsV2Input

    private let response: ListObjectsV2OutputResponse
    
    private var firstPageItems: [StorageListResult.Item]?

    /// Returns an [ObjectListing](x-source-tag://ObjectListing) with a pre-initialized initial
    /// response.
    ///
    /// - Tag: ObjectListing.create
    static func create(with client: S3ClientProtocol,
                       prefix: String,
                       input: ListObjectsV2Input) async throws -> StorageListing {
        let response = try await client.listObjectsV2(input: input)
        return StorageListing(client: client,
                              prefix: prefix,
                              input: input,
                              response: response)
    }
    
    /// - Returns: An array representing the contents of the first response from the listing request,
    ///            ignoring if a next page token was present.
    ///
    /// - Tag: ObjectListing.firstPage
    mutating func firstPage() async throws -> [StorageListResult.Item] {
        if let firstPageItems = firstPageItems {
            return firstPageItems
        }
        
        let result = try await createFirstPage()
        firstPageItems = result
        return result
    }
    
    /// Returns an async list of S3 objects.
    ///
    /// - Tag: ObjectListing.objectSequence
    var itemSequence: StorageItemPageSequence {
        return StorageItemPageSequence(client: self.client,
                                       prefix: self.prefix,
                                       input: self.input,
                                       response: self.response)
    }
    
    private func createFirstPage() async throws -> [StorageListResult.Item] {
        let sequence = self.itemSequence
        var iterator = sequence.makeAsyncIterator()
        return try await iterator.next() ?? []
    }
    
}
