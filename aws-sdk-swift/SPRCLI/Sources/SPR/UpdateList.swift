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
import ClientRuntime
import AWSCLIUtils

extension SPRPublisher {

    mutating func updateList() async throws {
        let s3Client = try S3Client(region: region)
        var list = try await verify(s3Client: s3Client)
        list.releases[version] = try makeRelease()
        try await upload(s3Client: s3Client, list: list)
        invalidations.append(listKey)
    }

    private func verify(s3Client: S3Client) async throws -> ListPackageReleases {
        let input = GetObjectInput(bucket: bucket, key: listKey)
        let list: ListPackageReleases
        do {
            let output = try await s3Client.getObject(input: input)
            guard let data = try await output.body?.readData() else {
                throw Error("Could not get version list.")
            }
            list = try JSONDecoder().decode(ListPackageReleases.self, from: data)
        } catch is NoSuchKey {
            list = ListPackageReleases(releases: [:])
        }
        guard !list.releases.keys.contains(version) || replace else {
            throw Error("This version already exists in the list.")
        }
        return list
    }

    private func makeRelease() throws -> ListPackageReleases.Release {
        try ListPackageReleases.Release(url: releaseURL, problem: nil)
    }

    private func upload(s3Client: S3Client, list: ListPackageReleases) async throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try jsonEncoder.encode(list)
        let body = ByteStream.data(data)
        let input = PutObjectInput(body: body, bucket: bucket, contentType: "application/json", key: listKey)
        _ = try await s3Client.putObject(input: input)
    }

    var listKey: String {
        "\(scope)/\(name)"
    }

    private var releaseURL: URL {
        get throws {
            guard let baseURL = URL(string: url) else {
                throw Error("URL is invalid")
            }
            return baseURL
                .appending(component: scope)
                .appending(component: name)
                .appending(component: version)
        }
    }
}
