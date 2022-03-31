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

    func deleteObject(input: DeleteObjectInput, completion: @escaping (ClientRuntime.SdkResult<DeleteObjectOutputResponse, DeleteObjectOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func listObjectsV2(input: ListObjectsV2Input, completion: @escaping (ClientRuntime.SdkResult<ListObjectsV2OutputResponse, ListObjectsV2OutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func listParts(input: ListPartsInput, completion: @escaping (ClientRuntime.SdkResult<ListPartsOutputResponse, ListPartsOutputError>) -> Void)
    {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func abortMultipartUpload(input: AbortMultipartUploadInput, completion: @escaping (ClientRuntime.SdkResult<AbortMultipartUploadOutputResponse, AbortMultipartUploadOutputError>) -> Void) {
#warning("Not Implemented")
        fatalError("Not Implemented")
    }
}
