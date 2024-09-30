//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import Foundation
import XCTest
import AWSS3
import AWSClientRuntime
import ClientRuntime
import AWSSSOAdmin
import AWSSDKIdentity

/* Prerequisites to run the SSO credentials provider integration test(s):
 *
 * [Manual]
 * 1. Enable IAM Identity Center AWS Organization for the AWS account used to run integration test if it hasn't been already.
 *
 * [Automatic]
 * 2. Create a read-only permission set in IAM Identity Center called "SSOCredProvIntegTestPermSet".
 *
 * [Manual]
 * 3. Create a user in IAM Identity Center.
 * 4. Give the created user access to your AWS account with the created permission set.
 * 5. Retrieve username, password, and SSO start URL of the IAM Identity Store user. Configure SSO config using these values (aws sso configure).
 * 6. Create SSO token using AWS CLI (aws sso login --profile <profile-name-set-during-aws-sso-configure>).
 * 7. Run the test.
 *
 * Note: Enabling AWS organization and creating IAM identity store have no exposed API as of 9/17/2023 for programmatic activation / creation.
 *
 * Step 1, 3, 4, 5 have to be done only once per account.
 */
class SSOAWSCredentialIdentityResolverTests : XCTestCase {
    var client: S3Client!
    var ssoClient: SSOAdminClient!
    // Change this region string to the region where AWS SSO instance is in.
    let region = "us-west-2"
    
    private var iamIdentityCenterInstanceArn: String = ""
    private var permissionSetArn: String = ""
    
    private let permissionSetName = "SSOCredProvIntegTestPermSet"
    private let awsReadOnlyPolicy = "arn:aws:iam::aws:policy/ReadOnlyAccess"
        
    override func setUp() async throws {
        try await super.setUp()
        // Use default credentials provider chain for setup
        ssoClient = try SSOAdminClient(region: "us-west-2")
        try await createPermissionSetIfNeeded()
        
        // Create a S3 client that uses SSO credentials provider
        try await setUpClient()
    }

    // The test calls listBuckets() and forces S3Client to use SSOAWSCredentialIdentityResolver
    // TODO: Re-enable this test once CI is configured to run it. See https://github.com/awslabs/aws-sdk-swift/issues/1311
    func xtest_listBuckets() async throws {
        _ = try await client.listBuckets(input: ListBucketsInput())
    }
    
    /* HELPER METHODS */
    private func createPermissionSetIfNeeded() async throws {
        // Get IAM identity center instanceArn
        iamIdentityCenterInstanceArn = try await getIamIdentityCenterArn()
        
        do {
            // Create permission set
            permissionSetArn = try await createPermissionSet()
            // Attach policy to permissino set just created
            try await attachReadOnlyPolicyToPermSet()
        } catch let error as AWSSSOAdmin.ConflictException {
            // Catch error if permission set has already been created from previous run of this integ test
            if let message = error.message, message.contains("\(permissionSetName) already exists") {
                return
            }
            throw error
        }
    }
    
    private func getIamIdentityCenterArn() async throws -> String {
        // Get IAM identity center instanceArn
        let listInstancesOutput = try await ssoClient.listInstances(input: ListInstancesInput())
        guard let iamCenterInstances = listInstancesOutput.instances, !iamCenterInstances.isEmpty, let iamCenterArn = iamCenterInstances[0].instanceArn else {
            throw ClientError.dataNotFound("No IAM Identity Center instance found. Check AWS organization is enabled for the account.")
        }
        return iamCenterArn
    }
    
    private func createPermissionSet() async throws -> String {
        // Create permission set and save its ARN
        let createPermissionSetOutput = try await ssoClient.createPermissionSet(input: CreatePermissionSetInput(
            description: "Permission set for testing SSO credentials provider.",
            instanceArn: iamIdentityCenterInstanceArn,
            name: permissionSetName
            
        ))
        guard let permSet = createPermissionSetOutput.permissionSet, let permSetArn = permSet.permissionSetArn else {
            throw ClientError.dataNotFound("Permission set arn could not be retrieved after creation.")
        }
        return permSetArn
    }
    
    private func attachReadOnlyPolicyToPermSet() async throws {
        // Attach ReadOnly AWS-managed policy to the created permission set
        _ = try await ssoClient.attachManagedPolicyToPermissionSet(input: AttachManagedPolicyToPermissionSetInput(
            instanceArn: iamIdentityCenterInstanceArn,
            managedPolicyArn: awsReadOnlyPolicy,
            permissionSetArn: permissionSetArn))
    }
    
    private func setUpClient() async throws {
        // Setup SSOAWSCredentialIdentityResolver
        let ssoAWSCredentialIdentityResolver = try SSOAWSCredentialIdentityResolver()

        // Setup S3ClientConfiguration to use SSOAWSCredentialIdentityResolver
        let testConfig = try await S3Client.S3ClientConfiguration()
        testConfig.awsCredentialIdentityResolver = ssoAWSCredentialIdentityResolver
        testConfig.region = region

        // Initialize our S3 client with the specified configuration
        client = S3Client(config: testConfig)
    }
}
