//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

protocol AWSS3Behavior {
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request) -> AWSTask<AWSS3ListObjectsV2Output>
    func deleteObject(_ request: AWSS3DeleteObjectRequest) -> AWSTask<AWSS3DeleteObjectOutput>

    func getS3() -> AWSS3
}
