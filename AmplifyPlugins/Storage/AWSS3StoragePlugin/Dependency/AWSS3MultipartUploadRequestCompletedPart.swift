//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3

struct AWSS3MultipartUploadRequestCompletedPart {
    let partNumber: Int
    let eTag: String

    init(partNumber: Int, eTag: String) {
        self.partNumber = partNumber
        self.eTag = eTag
    }
}

typealias AWSS3MultipartUploadRequestCompletedParts = [AWSS3MultipartUploadRequestCompletedPart]

extension AWSS3MultipartUploadRequestCompletedParts {

    init(completedParts: StorageUploadParts) {
        let eTags = completedParts.map { $0.eTag }
        let parts = eTags.indices.map { index in
            AWSS3MultipartUploadRequestCompletedPart(partNumber: index + 1, eTag: eTags[index] ?? "")
        }
        self = parts
    }

    init(parts: [S3ClientTypes.Part]) {
        self = parts.compactMap {
            guard let eTag = $0.eTag else {
                return nil
            }
            return AWSS3MultipartUploadRequestCompletedPart(partNumber: $0.partNumber, eTag: eTag)
        }
    }

}
