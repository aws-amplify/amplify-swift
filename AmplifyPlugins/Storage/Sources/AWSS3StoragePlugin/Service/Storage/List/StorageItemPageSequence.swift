//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Amplify
import Foundation

/// Concrete implementation of the an
/// [AsyncSequence](x-source-tag://AsyncSequence) used to produce
/// [StorageListResult](x-source-tag://StorageListResult) listings.
///
/// - Tag: StorageItemPageSequence
struct StorageItemPageSequence {

    var client: S3ClientProtocol

    var prefix: String

    var input: ListObjectsV2Input

    var response: ListObjectsV2OutputResponse
}

extension StorageItemPageSequence: AsyncSequence {
    typealias Element = [StorageListResult.Item]
    typealias AsyncIterator = StorageItemPageIterator
    func makeAsyncIterator() -> AsyncIterator {
        return StorageItemPageIterator(client: self.client,
                                       prefix: self.prefix,
                                       input: self.input,
                                       response: self.response)
    }
}
