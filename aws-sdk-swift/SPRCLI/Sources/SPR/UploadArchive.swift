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

    mutating func uploadArchive() async throws {
        let tmpDirFileURL = FileManager.default.temporaryDirectory
        let archiveFileURL = tmpDirFileURL.appending(component: "\(UUID().uuidString).zip")
        let archiveProcess = Process.SPR.archive(name: name, packagePath: path, archiveFileURL: archiveFileURL)
        _ = try _runReturningStdOut(archiveProcess)
        guard FileManager.default.fileExists(atPath: urlPath(archiveFileURL)) else {
            throw Error("Archive process succeeded but archive does not exist.")
        }
        let checksumProcess = Process.SPR.checksum(archiveFileURL: archiveFileURL)
        let checksumStdout = try _runReturningStdOut(checksumProcess)
        guard let checksum = checksumStdout?.split(separator: " ").first else {
            throw Error("Checksum could not be parsed. Output: \(checksumStdout ?? "<none>")")
        }
        self.checksum = String(checksum)
        let s3Client = try S3Client(region: region)
        try await verify(s3Client: s3Client)
        try await upload(s3Client: s3Client, archiveFileURL: archiveFileURL)
    }

    private func verify(s3Client: S3Client) async throws {
        do {
            let input = GetObjectInput(bucket: bucket, key: archiveKey)
            _ = try await s3Client.getObject(input: input)
            // If getObject did not throw, the archive must already exist.
            guard replace else {
                throw Error("Archive for this version already exists.")
            }
        } catch is NoSuchKey {
            // This is expected.  Any other error is unexpected and should
            // throw back to the caller.
        }
    }

    private func upload(s3Client: S3Client, archiveFileURL: URL) async throws {
        let fileHandle = try FileHandle(forReadingFrom: archiveFileURL)
        let stream = FileStream(fileHandle: fileHandle)
        let body = ByteStream.stream(stream)
        let input = PutObjectInput(body: body, bucket: bucket, contentType: "application/zip", key: archiveKey)
        _ = try await s3Client.putObject(input: input)
    }

    private var archiveKey: String {
        "\(scope)/\(name)/\(version).zip"
    }
}
