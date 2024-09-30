//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

public struct IMDSRegionProvider: RegionProvider {
    private let REGION_PATH = "/latest/meta-data/placement/region"
    let imdsClient: IMDSClient

    public init() throws {
        self.imdsClient = try IMDSClient()
    }

    public func getRegion() async throws -> String? {
        return try await imdsClient.get(path: REGION_PATH)
    }
}
