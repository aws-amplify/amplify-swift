//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSIAM
import AWSSTS
import AWSCloudWatchLogs
import AWSEC2
import ClientRuntime

class IMDSAWSCredentialIdentityResolverTests: XCTestCase {
    private let region = "us-west-2"
    private var ec2Client: EC2Client!
    private var iamClient: IAMClient!
    private var stsClient: STSClient!
    private var cloudWatchLogClient: CloudWatchLogsClient!

    // Poll amount maixmum with a 10 second wait between each attempt.
    private var maxPollLogGroupCreation = 50
    private var maxPollLogMessageFound = 10

    // MARK: - SETUP & TEARDOWN

    override func setUp() async throws {
        ec2Client = try EC2Client(region: region)
        iamClient = try IAMClient(region: region)
        stsClient = try STSClient(region: region)
        cloudWatchLogClient = try CloudWatchLogsClient(region: region)
        try await launchEC2Instance()
        // Wait until cloud watch log group is created by shell script passed to EC2 instance at launch.
        try await cloudWatchLogSetup()
    }

    // IAM role & instance profile and docker image in ECR private repo are kept for re-use.
    override func tearDown() async throws {
        _ = try await ec2Client.terminateInstances(input: TerminateInstancesInput(
            instanceIds: [ec2InstanceID]
        ))
        _ = try await cloudWatchLogClient.deleteLogGroup(
            input: DeleteLogGroupInput(logGroupName: cloudWatchLogGroupName)
        )
    }

    // MARK: - TEST CASE

    // Delete `x` to enable test.
    func xtestIMDSAWSCredentialIdentityResolver() async throws {
        var pollCount = 0
        var (statusLogFound, logsContainSuccessKeyword, logsContainFailureKeyword) = (false, false, false)
        while (!statusLogFound && pollCount < maxPollLogMessageFound) {
            pollCount += 1
            logsContainSuccessKeyword = try await checkLogsForKeyword(keyword: "imds-integration-test-success")
            logsContainFailureKeyword = try await checkLogsForKeyword(keyword: "imds-integration-test-failure")
            statusLogFound = logsContainSuccessKeyword || logsContainFailureKeyword
            if (!statusLogFound) {
                try await pauseFor(numSeconds: 10.0)
            }
        }
        XCTAssertTrue(
            logsContainSuccessKeyword,
            "Logs did not contain the expected success keyword. Test failed!"
        )
    }

    // MARK: - HELPER FUNCTIONS & ERROR ENUM

    private let accessPolicyName = "imds-integ-test-access-policy"
    private var accountID: String!
    private var amiID: String!
    private let cloudWatchLogGroupName = "imds-log-group"
    private let cloudWatchLogStreamName = "imds-log-stream"
    private let dockerImageName = "imds-integ-test:latest"
    private var ec2InstanceID: String!
    private var ecrRepoURL: String!
    private let instanceProfileName = "imds-integ-test-instance-profile"
    private var roleARN: String!
    private let roleName = "imds-integ-test-role"
    private var securityGroupID: String!
    private let securityGroupName = "imds-integ-test-security-group"

    private func launchEC2Instance() async throws {
        try await createInstanceProfileIfMissing()
        try await createSecurtyGroupIfMissing()
        amiID = try await getAMIID()
        let input = try await createRunInstancesInput()
        // Launch the EC2 instance.
        let response = try await ec2Client.runInstances(input: input)
        ec2InstanceID = response.instances?[0].instanceId
    }

    private func createInstanceProfileIfMissing() async throws {
        let profileExists = try await iamClient.listInstanceProfiles(
            input: ListInstanceProfilesInput())
            .instanceProfiles?
            .contains(where: { $0.instanceProfileName == instanceProfileName })
        guard let profileExists, !profileExists else {
            return
        }
        // Policy documents
        let assumeRolePolicy = """
        { "Version": "2012-10-17", "Statement": [ { 
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" },
        "Action": "sts:AssumeRole" } ] }
        """
        let accessPolicy = """
        { "Version": "2012-10-17", "Statement": [ {
        "Effect": "Allow",
        "Action": [ "sts:GetCallerIdentity",
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer",
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:DescribeLogStreams",
                    "logs:PutLogEvents" ],
        "Resource": ["*"] } ] }
        """
        roleARN = try await iamClient.createRole(input: CreateRoleInput(
            assumeRolePolicyDocument: assumeRolePolicy,
            roleName: roleName
        )).role?.arn
        // Add in-line access policy to role
        _ = try await iamClient.putRolePolicy(input: PutRolePolicyInput(
            policyDocument: accessPolicy,
            policyName: accessPolicyName,
            roleName: roleName
        ))
        _ = try await iamClient.createInstanceProfile(input: CreateInstanceProfileInput(
            instanceProfileName: instanceProfileName
        ))
        _ = try await iamClient.addRoleToInstanceProfile(input: AddRoleToInstanceProfileInput(
            instanceProfileName: instanceProfileName,
            roleName: roleName
        ))
        // Wait for role creation to propagate
        try await pauseFor(numSeconds: 15.0)
    }

    private func createSecurtyGroupIfMissing() async throws {
        let securityGroupExists = try await ec2Client.describeSecurityGroups(
            input: DescribeSecurityGroupsInput(
                groupNames: [securityGroupName])
        ).securityGroups?.contains(where: { $0.groupName == securityGroupName })
        guard let securityGroupExists, !securityGroupExists else {
            return
        }
        securityGroupID = try await ec2Client.createSecurityGroup(input: CreateSecurityGroupInput(
            description: "Security group used for IMDSAWSCredentialIdentityResolverTests.",
            groupName: securityGroupName
        )).groupId
        // Allow HTTP & HTTPS inbound connections.
        try await addIngressRulesToSecurityGroup()
    }

    private func addIngressRulesToSecurityGroup() async throws {
        _ = try await ec2Client.authorizeSecurityGroupIngress(input: AuthorizeSecurityGroupIngressInput(
            groupId: securityGroupID,
            ipPermissions: [
                EC2ClientTypes.IpPermission(
                    fromPort: 80,
                    ipProtocol: "tcp",
                    ipRanges: [EC2ClientTypes.IpRange(cidrIp: "0.0.0.0/0", description: "All HTTP")],
                    toPort: 80
                ),
                EC2ClientTypes.IpPermission(
                    fromPort: 443,
                    ipProtocol: "tcp",
                    ipRanges: [EC2ClientTypes.IpRange(cidrIp: "0.0.0.0/0", description: "All HTTPS")],
                    toPort: 443
                )
            ]
        ))
    }

    private func getAMIID() async throws -> String? {
        return try await ec2Client.describeImages(input: DescribeImagesInput(
            filters: [
                /*
                 The space between `2` and `*` in "Amazon Linux 2 *" is not an accident.
                 It prevents Amazon Linux 2023 from being fetched as well.
                */
                EC2ClientTypes.Filter(name: "description", values: ["*Amazon Linux 2 *"]),
                EC2ClientTypes.Filter(name: "architecture", values: ["arm64"]),
                EC2ClientTypes.Filter(name: "image-type", values: ["machine"]),
                EC2ClientTypes.Filter(name: "is-public", values: ["true"]),
                EC2ClientTypes.Filter(name: "state", values: ["available"])
            ],
            owners: ["amazon"]
        )).images?[0].imageId
    }

    private func createRunInstancesInput() async throws -> RunInstancesInput {
        accountID = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput()).account
        ecrRepoURL = "\(accountID).dkr.ecr.\(region).amazonaws.com"

        let userDataScriptEncoded = """
        #!/bin/bash
        sudo yum update -y
        sudo yum install docker -y
        sudo yum install awslogs -y
        sudo systemctl start docker
        sudo systemctl start awslogsd
        aws ecr get-login-password --region \(region) \
        | sudo docker login --username AWS --password-stdin \(ecrRepoURL)
        sudo docker run \
        --log-driver=awslogs \
        --log-opt awslogs-region=us-west-2 \
        --log-opt awslogs-group=\(cloudWatchLogGroupName) \
        --log-opt awslogs-stream=\(cloudWatchLogStreamName) \
        --log-opt awslogs-create-group=true \
        \(ecrRepoURL)/\(dockerImageName)
        """.data(using: .utf8)?.base64EncodedString()

        let input = RunInstancesInput(
            blockDeviceMappings: [EC2ClientTypes.BlockDeviceMapping(
                deviceName: "/dev/xvda",
                ebs: EC2ClientTypes.EbsBlockDevice(
                    deleteOnTermination: true,
                    encrypted: false,
                    volumeSize: 35,
                    volumeType: EC2ClientTypes.VolumeType.gp2))
            ],
            iamInstanceProfile: EC2ClientTypes.IamInstanceProfileSpecification(
                name: instanceProfileName
            ),
            imageId: amiID,
            instanceType: EC2ClientTypes.InstanceType.m7gMedium,
            //keyName: keyName,
            maxCount: 1,
            // Hop limit must be 2 for containerized application in EC2 instance to reach IMDS.
            metadataOptions: EC2ClientTypes.InstanceMetadataOptionsRequest(httpPutResponseHopLimit: 2),
            minCount: 1,
            securityGroups: [securityGroupName],
            // A bash script that sets up docker and runs it is passed as user-data.
            userData: userDataScriptEncoded
        )
        return input
    }

    private func cloudWatchLogSetup() async throws {
        var pollCount = 0
        var logGroupInitialized = false
        while (!logGroupInitialized && pollCount < maxPollLogGroupCreation) {
            pollCount += 1
            // Check if log groups exists.
            let logGroups = try await cloudWatchLogClient.describeLogGroups(
                input: DescribeLogGroupsInput()
            ).logGroups
            if let logGroups, logGroups.contains(where: { $0.logGroupName == cloudWatchLogGroupName }) {
                logGroupInitialized = true
            }
            try await pauseFor(numSeconds: 10.0)
        }
        // Throw if no log group was found within the time limit.
        if (!logGroupInitialized) {
            throw IMDSError.logGroupCreationFailed("No log group for the integration test was found.")
        }
    }

    // Checks cloud watch logs for a keyword string.
    private func checkLogsForKeyword(keyword: String) async throws -> Bool {
        let logEvents = try await cloudWatchLogClient.getLogEvents(input: GetLogEventsInput(
            logGroupName: cloudWatchLogGroupName,
            logStreamName: cloudWatchLogStreamName
        ))
        for event in logEvents.events ?? [] {
            if let message = event.message, message.contains(keyword) {
                return true
            }
        }
        return false
    }

    private func pauseFor(numSeconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(numSeconds * 1_000_000_000))
    }

    private enum IMDSError: Error {
        case logGroupCreationFailed(String)
    }
}

private extension String.StringInterpolation {
    /// Prints `Optional` values by only interpolating it if the value is set. `nil` is used as a fallback value to provide a clear output.
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
        appendInterpolation(value ?? "nil" as CustomStringConvertible)
    }
}
