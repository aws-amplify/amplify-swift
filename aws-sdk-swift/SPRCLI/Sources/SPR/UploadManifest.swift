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

    func uploadManifest() async throws {
        let packageFileURL = URL(fileURLWithPath: path).standardizedFileURL
        let manifestFileURL = packageFileURL.appending(component: "Package.swift")
        let s3Client = try S3Client(region: region)
        try await verify(s3Client: s3Client)
        try await upload(s3Client: s3Client, manifestFileURL: manifestFileURL)
    }

    private func verify(s3Client: S3Client) async throws {
        do {
            let input = GetObjectInput(bucket: bucket, key: manifestKey)
            _ = try await s3Client.getObject(input: input)
            guard replace else {
                throw Error("Package.swift for this version already exists.")
            }
        } catch is NoSuchKey {
            // This is expected.  Any other error is unexpected and should
            // throw back to the caller.
        }
    }

    private func upload(s3Client: S3Client, manifestFileURL: URL) async throws {
        let fileHandle = try FileHandle(forReadingFrom: manifestFileURL)
        let stream = FileStream(fileHandle: fileHandle)
        let body = ByteStream.stream(stream)
        let input = PutObjectInput(body: body, bucket: bucket, contentType: "text/x-swift", key: manifestKey)
        _ = try await s3Client.putObject(input: input)
    }

    private var manifestKey: String {
        "\(scope)/\(name)/\(version)/Package.swift"
    }
}
