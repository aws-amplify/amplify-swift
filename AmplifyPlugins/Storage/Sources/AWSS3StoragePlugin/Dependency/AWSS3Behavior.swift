//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

//import AWSS3
//import ClientRuntime
//import AWSClientRuntime

// Behavior that the implemenation class for AWSS3 will use.
protocol AWSS3Behavior {

    

    // Deletes object.
    func deleteObject(_ request: AWSS3DeleteObjectRequest) async throws

    // Lists objects in a bucket.
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request) async throws -> StorageListResult

    // Creates a Multipart Upload.
    func createMultipartUpload(_ request: CreateMultipartUploadRequest) async throws -> AWSS3CreateMultipartUploadResponse

    // Get list of uploaded parts (supports development)
    func listParts(bucket: String, key: String, uploadId: UploadID) async throws -> AWSS3ListUploadPartResponse

    // Completes a Multipart Upload.
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest) async throws -> AWSS3CompleteMultipartUploadResponse

    // Aborts a Multipart Upload.
    func abortMultipartUpload(_ request: AWSS3AbortMultipartUploadRequest) async throws

    // Gets a client for AWS S3 Service.
//    func getS3() -> S3ClientProtocol

}

//extension AWSS3Behavior {
//    func listParts(bucket: String, key: String, uploadId: UploadID, completion: @escaping (Result<ListPartsOutputResponse, StorageError>) -> Void) {
//        // do nothing
//    }
//}
