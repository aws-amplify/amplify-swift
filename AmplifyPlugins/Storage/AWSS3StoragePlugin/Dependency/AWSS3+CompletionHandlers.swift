//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import ClientRuntime
import AWSClientRuntime

extension S3Client {

    func deleteObject(input: DeleteObjectInput, completion: @escaping (SdkResult<DeleteObjectOutputResponse, DeleteObjectOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func listObjectsV2(input: ListObjectsV2Input, completion: @escaping (SdkResult<ListObjectsV2OutputResponse, ListObjectsV2OutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func listParts(input: ListPartsInput, completion: @escaping (SdkResult<ListPartsOutputResponse, ListPartsOutputError>) -> Void)
    {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func abortMultipartUpload(input: AbortMultipartUploadInput, completion: @escaping (SdkResult<AbortMultipartUploadOutputResponse, AbortMultipartUploadOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }
    
    func createMultipartUpload(input: CreateMultipartUploadInput, completion: @escaping (SdkResult<CreateMultipartUploadOutputResponse, CreateMultipartUploadOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }
    
    func completeMultipartUpload(input: CompleteMultipartUploadInput, completion: @escaping (SdkResult<CompleteMultipartUploadOutputResponse, CompleteMultipartUploadOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }
}
