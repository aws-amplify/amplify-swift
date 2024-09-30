//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Smithy
import SmithyStreams
import AWSCLIUtils

extension SPRPublisher {

    func uploadMetadata() async throws {
        let s3Client = try S3Client(region: region)
        try await verify(s3Client: s3Client)
        try await upload(s3Client: s3Client)
    }

    private func verify(s3Client: S3Client) async throws {
        do {
            let input = GetObjectInput(bucket: bucket, key: metadataKey)
            _ = try await s3Client.getObject(input: input)
            guard replace else {
                throw Error("Metadata for this version already exists.")
            }
        } catch is NoSuchKey {
            // This is expected.  Any other error is unexpected and should
            // throw back to the caller.
        }
    }

    private func upload(s3Client: S3Client) async throws {
        let metadata = createMetadata()
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try jsonEncoder.encode(metadata)
        let body = ByteStream.data(data)
        let input = PutObjectInput(body: body, bucket: bucket, contentType: "application/json", key: metadataKey)
        _ = try await s3Client.putObject(input: input)
    }

    private var metadataKey: String {
        "\(scope)/\(name)/\(version)"
    }

    private func createMetadata() -> PackageInfo {
        let now = Date().ISO8601Format()
        let organization = PackageInfo.Metadata.Author.Organization(name: "Amazon Web Services", email: nil, description: nil, url: URL(string: "https://aws.amazon.com/")!)
        let author = PackageInfo.Metadata.Author(name: "AWS SDK for Swift Team", email: nil, description: nil, organization: organization, url: nil)
        let resource = Resource(name: "source-archive", type: "application/zip", checksum: checksum, signing: nil)
        let metadata = PackageInfo.Metadata(author: author, description: "A Swift package, what can I say?", licenseURL: nil, originalPublicationTime: now, readmeURL: nil, repositoryURLs: nil)
        return PackageInfo(id: "\(scope).\(name)", version: version, resources: [resource], metadata: metadata, publishedAt: now)
    }
}
