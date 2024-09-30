//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime

public struct SPRPublisher {

    public var scope: String
    public var name: String
    public var version: String
    public var path: String
    public var region: String = ""
    public var bucket: String?
    public var url: String
    public var distributionID: String?
    public var replace = false

    var checksum = ""
    public var invalidations = [String]()

    public init(
        scope: String,
        name: String,
        version: String,
        path: String,
        region: String,
        bucket: String?,
        url: String,
        distributionID: String?,
        replace: Bool
    ) {
        self.scope = scope
        self.name = name
        self.version = version
        self.path = path
        self.region = region
        self.bucket = bucket
        self.url = url
        self.distributionID = distributionID
        self.replace = replace
    }

    public mutating func run() async throws {
        await setOptions()
        print("    Verifying package...               ", terminator: "")
        try verifyPackage()
        print("[done]")
        print("    Generating & uploading archive...  ", terminator: "")
        try await uploadArchive()
        print("[done]")
        print("    Uploading Package.swift...         ", terminator: "")
        try await uploadManifest()
        print("[done]")
        print("    Uploading package metadata...      ", terminator: "")
        try await uploadMetadata()
        print("[done]")
        print("    Updating package list...           ", terminator: "")
        try await updateList()
        print("[done]")
    }

    private mutating func setOptions() async {
        await SDKLoggingSystem.initialize(logLevel: .error)
        let env = ProcessInfo.processInfo.environment
        bucket = bucket ?? env["AWS_SDK_SPR_BUCKET"]
        if region.isEmpty {
            region = env["AWS_SDK_SPR_REGION"] ?? "us-east-1"
        }
        distributionID = Self.resolvedDistributionID(from: distributionID)
    }

    static func resolvedDistributionID(from distributionID: String?) -> String? {
        let env = ProcessInfo.processInfo.environment
        return distributionID ?? env["AWS_SDK_SPR_DISTRIBUTION_ID"]
    }
}
