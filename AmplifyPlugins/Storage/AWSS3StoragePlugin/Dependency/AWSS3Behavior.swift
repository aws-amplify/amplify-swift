//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

import AWSS3
import ClientRuntime
import AWSClientRuntime

// Behavior that the implemenation class for AWSS3 will use.
protocol AWSS3Behavior {

    // Deletes object.
    func deleteObject(_ request: AWSS3DeleteObjectRequest, completion: @escaping (Result<Void, StorageError>) -> Void)

    // Lists objects in a bucket.
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request, completion: @escaping (Result<StorageListResult, StorageError>) -> Void)

    // Gets instance of AWS Service.
    func getS3() -> S3Client

}
