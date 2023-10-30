//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation
import AWSPluginsCore

struct S3ClientConfiguration {
    let region: String
    let credentialsProvider: CredentialsProvider
    let accelerate: Bool
}

class S3Client {
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
