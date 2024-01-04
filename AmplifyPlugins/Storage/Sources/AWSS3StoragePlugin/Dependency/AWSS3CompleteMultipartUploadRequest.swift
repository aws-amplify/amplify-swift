//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

struct AWSS3CompleteMultipartUploadRequest {
    let bucket: String
    let key: String
    let uploadId: String
    let parts: [AWSS3MultipartUploadRequestCompletedPart]
}
