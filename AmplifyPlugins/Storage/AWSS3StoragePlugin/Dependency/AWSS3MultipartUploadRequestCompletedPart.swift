//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct AWSS3MultipartUploadRequestCompletedPart {
    let partNumber: Int
    let eTag: String
    
    init(partNumber: Int, eTag: String) {
        self.partNumber = partNumber
        self.eTag = eTag
    }
}
