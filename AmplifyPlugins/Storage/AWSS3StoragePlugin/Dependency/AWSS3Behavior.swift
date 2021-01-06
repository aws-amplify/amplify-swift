//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

// Behavior that the implemenation class for AWSS3 will use.
protocol AWSS3Behavior {

    // List objects
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request) -> AWSTask<AWSS3ListObjectsV2Output>

    // Delete objects
    func deleteObject(_ request: AWSS3DeleteObjectRequest) -> AWSTask<AWSS3DeleteObjectOutput>

    // return the instance of AWSS3
    func getS3() -> AWSS3
}
