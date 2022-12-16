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

    // Creates a Multipart Upload.
    func createMultipartUpload(_ request: CreateMultipartUploadRequest, completion: @escaping (Result<AWSS3CreateMultipartUploadResponse, StorageError>) -> Void)

    // Get list of uploaded parts (supports development)
    func listParts(bucket: String, key: String, uploadId: UploadID, completion: @escaping (SdkResult<ListPartsOutputResponse, ListPartsOutputError>) -> Void)

    // Completes a Multipart Upload.
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest, completion: @escaping (Result<AWSS3CompleteMultipartUploadResponse, StorageError>) -> Void)

    // Aborts a Multipart Upload.
    func abortMultipartUpload(_ request: AWSS3AbortMultipartUploadRequest, completion: @escaping (Result<Void, StorageError>) -> Void)

    // Gets a client for AWS S3 Service.
    func getS3() -> S3Client

}

extension AWSS3Behavior {
    func listParts(bucket: String, key: String, uploadId: UploadID, completion: @escaping (SdkResult<ListPartsOutputResponse, ListPartsOutputError>) -> Void) {
        // do nothing
    }
}
