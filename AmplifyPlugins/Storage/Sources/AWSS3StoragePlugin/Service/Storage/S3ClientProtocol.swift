//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import ClientRuntime

protocol S3ClientProtocol {

    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutput

    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2Output

    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutput

    func listParts(input: ListPartsInput) async throws -> ListPartsOutput

    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutput

    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutput

    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutput

}

extension S3Client: S3ClientProtocol { }
