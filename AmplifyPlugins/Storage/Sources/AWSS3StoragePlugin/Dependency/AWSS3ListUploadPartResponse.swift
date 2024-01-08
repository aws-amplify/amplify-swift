//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSS3

struct AWSS3ListUploadPartResponse {
    let bucket: String
    let key: String
    let uploadId: String
    let parts: AWSS3MultipartUploadRequestCompletedParts
}

extension AWSS3ListUploadPartResponse {

    init?(response: ListPartsOutput) {
        guard let bucket = response.bucket,
              let key = response.key,
              let uploadId = response.uploadId,
              let parts = response.parts else {
                  return nil
              }
        self.bucket = bucket
        self.key = key
        self.uploadId = uploadId
        self.parts = AWSS3MultipartUploadRequestCompletedParts(parts: parts)
    }

}
