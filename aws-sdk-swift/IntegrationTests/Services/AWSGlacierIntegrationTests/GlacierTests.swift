//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSGlacier
import AWSSTS
import enum Smithy.ByteStream
import SmithyWaitersAPI

/// Tests that Glacier operations run successfully
class GlacierTests: XCTestCase {
    var glacierClient: GlacierClient!
    var stsClient: STSClient!
    var accountId: String!
    var archiveId: String!
    let vaultName = UUID().uuidString.split(separator: "-").first!.lowercased() + "integ-test-vault"

    override func setUp() async throws {
        stsClient = try STSClient(region: "us-east-1")
        accountId = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput()).account
        glacierClient = try GlacierClient(region: "us-east-1")
    }

    override func tearDown() async throws {
        let deleteVaultInput = DeleteVaultInput(accountId: nil, vaultName: vaultName)
        _ = try await glacierClient.deleteVault(input: deleteVaultInput)
    }

    func testCreateVault() async throws {
        // Intentionally set accountId to nil for testing customization that sets it to '-' if nil
        let createVaultInput = CreateVaultInput(accountId: nil, vaultName: vaultName)
        let vaultURI = try await glacierClient.createVault(input: createVaultInput).location
        let expectedURI = "/\(accountId!)/vaults/\(vaultName)"
        XCTAssertEqual(expectedURI, vaultURI)
    }
}

