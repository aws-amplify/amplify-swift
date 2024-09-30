//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSSTS
import AWSIAM
import AWSCognitoIdentity
import ClientRuntime
import AWSClientRuntime
import Foundation
import AWSSDKIdentity

/// Tests STS web identity credentials provider using STS::getCallerIdentity.
class STSWebIdentityAWSCredentialIdentityResolverTests: XCTestCase {
    private let region = "us-east-1"

    // MARK: - The client used by test case

    // STS client with only the STS web identity credentials provider configured.
    private var webIdentityStsClient: STSClient!
    private var stsConfig: STSClient.STSClientConfiguration!

    // MARK: - Cognito things

    // Used to create identity pools and fetch cognito ID & OIDC token from it.
    private var cognitoIdentityClient: CognitoIdentityClient!
    // Regular STS client used to fetch the account ID used in fetching cognito ID.
    private var stsClient: STSClient!
    private let identityPoolName = "aws-sts-integration-test-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
    private var identityPoolId: String!
    private var oidcToken: String!
    private var oidcTokenFilePath: String!

    // MARK: - IAM things

    // Used to create temporary role assumed by STS web identity credentials provider.
    private var iamClient: IAMClient!
    private let roleName = "aws-sts-integration-test-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
    private let roleSessionName = "aws-sts-integration-test-\(UUID().uuidString.split(separator: "-").first!.lowercased())"
    private var roleArn: String!
    // JSON assume role policy
    private let assumeRolePolicy = """
    {"Version": "2012-10-17","Statement": [{"Sid": "","Effect": "Allow",
    "Principal": {"Federated": "cognito-identity.amazonaws.com"},"Action": [
    "sts:AssumeRoleWithWebIdentity"],"Condition": {"ForAnyValue:StringLike": {
    "cognito-identity.amazonaws.com:amr": "unauthenticated"}}}]}
    """
    private let identityPolicyName = "allow-STS-getCallerIdentity"
    // JSON identity policy
    private let roleIdentityPolicy = """
    {"Version": "2012-10-17","Statement": [{"Sid": "","Effect": "Allow",
    "Action": "sts:GetCallerIdentity","Resource": "*"}]}
    """

    // MARK: - SETUP & TEARDOWN

    override func setUp() async throws {
        try await super.setUp()

        // Create the role to be assumed in exchange for web identity token
        try await createRoleToBeAssumed()

        // Attach identity policy to role
        try await attachIdentityPolicyToRole()

        // Create the Cognito identity pool that allows unauthenticated identities
        try await createCognitoIdentityPool()

        // Get OIDC token from Cognito
        try await getAndCacheOIDCTokenFromCognito()

        // Construct STS Client config with only STS web identity crednentials provider
        try await constructSTSConfigWithWebIdentityAWSCredentialIdentityResolver()

        // Construct STS client that uses STS web identity credentials provider
        webIdentityStsClient = STSClient(config: stsConfig)
    }

    override func tearDown() async throws {
        // Delete inline identity policy of the role
        try await deleteInlineRolePolicy()

        // Delete role
        _ = try await iamClient.deleteRole(input: DeleteRoleInput(roleName: roleName))

        // Delete Cognito identity pool
        _ = try await cognitoIdentityClient.deleteIdentityPool(
            input: DeleteIdentityPoolInput(identityPoolId: identityPoolId)
        )

        // Delete token file
        try deleteTokenFile()
    }

    // MARK: - TEST CASE

    // Confirm STS web identity credentials provider works by validating response.
    func testGetCallerIdentity() async throws {
        let response = try await webIdentityStsClient.getCallerIdentity(
            input: GetCallerIdentityInput()
        )

        // Ensure returned caller info aren't nil
        let account = try XCTUnwrap(response.account)
        let userId = try XCTUnwrap(response.userId)
        let arn = try XCTUnwrap(response.arn)

        // Ensure returned caller info aren't empty strings
        XCTAssertNotEqual(account, "")
        XCTAssertNotEqual(userId, "")
        XCTAssertNotEqual(arn, "")
    }

    // MARK: - SETUP HELPER FUNCTIONS

    private func createRoleToBeAssumed() async throws {
        iamClient = try IAMClient(region: region)
        roleArn = try await iamClient.createRole(input: CreateRoleInput(
            assumeRolePolicyDocument: assumeRolePolicy,
            roleName: roleName
        )).role?.arn
        // This wait is necessary for role creation to propagate everywhere
        let seconds = 10
        let NSEC_PER_SEC = 1_000_000_000
        try await Task.sleep(nanoseconds: UInt64(seconds * NSEC_PER_SEC))
    }

    private func attachIdentityPolicyToRole() async throws {
        _ = try await iamClient.putRolePolicy(input: PutRolePolicyInput(
            policyDocument: roleIdentityPolicy,
            policyName: identityPolicyName,
            roleName: roleName
        ))
    }

    private func createCognitoIdentityPool() async throws {
        cognitoIdentityClient = try CognitoIdentityClient(region: region)
        let identityPool = try await cognitoIdentityClient.createIdentityPool(
            input: CreateIdentityPoolInput(
                allowUnauthenticatedIdentities: true,
                identityPoolName: identityPoolName
        ))
        identityPoolId = identityPool.identityPoolId
    }

    private func saveTokenIntoFile() throws {
        oidcTokenFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("token.txt").pathExtension
        let tokenData = oidcToken.data(using: String.Encoding.utf8)
        let fileCreated = FileManager.default.createFile(
            atPath: oidcTokenFilePath, contents: tokenData, attributes: nil
        )
        if !fileCreated {
            throw TokenFileError.tokenFileCreationFailed("Failed to create token text file.")
        }
    }

    private func getAndCacheOIDCTokenFromCognito() async throws {
        // Get Cognito ID from Cognito identity pool
        stsClient = try STSClient(region: region)
        let accountId = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput()).account
        let cognitoId = try await cognitoIdentityClient.getId(input: GetIdInput(
            accountId: accountId, identityPoolId: identityPoolId
        ))
        // Get OIDC token from Cognito identity pool using Cognito ID
        oidcToken  = try await cognitoIdentityClient.getOpenIdToken(
            input: GetOpenIdTokenInput(identityId: cognitoId.identityId)
        ).token
        // Save OIDC token to a file then save filepath
        try saveTokenIntoFile()
    }

    private func constructSTSConfigWithWebIdentityAWSCredentialIdentityResolver() async throws {
        let webIdentityAWSCredentialIdentityResolver = try STSWebIdentityAWSCredentialIdentityResolver(
            region: region,
            roleArn: roleArn,
            roleSessionName: roleSessionName,
            tokenFilePath: oidcTokenFilePath
        )
        stsConfig = try await STSClient.STSClientConfiguration(
            awsCredentialIdentityResolver: webIdentityAWSCredentialIdentityResolver,
            region: region
        )
    }

    // MARK: - TEARDOWN HELPER FUNCTIONS

    private func deleteInlineRolePolicy() async throws {
        let policyName = try await iamClient.listRolePolicies(input: ListRolePoliciesInput(roleName: roleName)).policyNames
        _ = try await iamClient.deleteRolePolicy(input: DeleteRolePolicyInput(
            policyName: policyName?[0], roleName: roleName
        ))
    }

    private func deleteTokenFile() throws {
        do {
            try FileManager.default.removeItem(atPath: oidcTokenFilePath)
        } catch {
            throw TokenFileError.tokenFileDeletionFailed("Failed to delete token text file.")
        }
    }

    // MARK: - ERROR USED IN SETUP & TEARDOWN

    enum TokenFileError: Error {
        case tokenFileCreationFailed(String)
        case tokenFileDeletionFailed(String)
    }
}
