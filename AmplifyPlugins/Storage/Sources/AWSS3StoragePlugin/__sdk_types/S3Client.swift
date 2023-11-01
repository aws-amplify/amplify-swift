//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

class S3Client: S3ClientProtocol {
    let configuration: S3ClientConfiguration

    init(configuration: S3ClientConfiguration) {
        self.configuration = configuration
    }

    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse { fatalError() }


    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse { fatalError() }

    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse { fatalError() }


    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse { fatalError() }


    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse { fatalError() }


    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse { fatalError() }

    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse {
        fatalError()
    }
}

protocol S3ClientProtocol {
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse
    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse
    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse
    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse
}
