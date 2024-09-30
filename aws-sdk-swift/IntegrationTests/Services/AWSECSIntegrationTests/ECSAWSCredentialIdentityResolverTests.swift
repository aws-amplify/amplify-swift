//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import AWSCloudWatchLogs
import AWSECS
import AWSEC2
import AWSIAM
import AWSSTS
import ClientRuntime

class ECSAWSCredentialIdentityResolverTests: XCTestCase {
    
    private let taskRoleName = "ecs_integ_test_task_role"
    private let executionRoleName = "ecs_integ_test_execution_role"
    private let clusterName = "ecs-integ-test-cluster"
    private let taskFamilyName = "ecs-integ-test-family"
    private let serviceName = "ecs-integ-test-service"
    private let logGroupName = "/ecs/integ-test-group"
    
    private var taskRoleArn: String? = nil
    private var executionRoleArn: String? = nil
    private var networkingConfig: ECSClientTypes.NetworkConfiguration = ECSClientTypes.NetworkConfiguration()
    private var taskDefArn: String = ""
    
    override func setUp() async throws {
        try await setupIAMRolesAndPolicies()
        try await setupCloudwatchLogs()
        try await setupNetworkingConfig(
            securityGroupNames: ["default"],
            availabilityZones: ["us-east-1a", "us-east-1b"]
        )
    }
    
    // TODO: Re-enable this test once CI is configured to run it. See https://github.com/awslabs/aws-sdk-swift/issues/1310
    func xtest_ecsAWSCredentialIdentityResolver() async throws {
        let ecsClient = try await ECSClient()
        
        // create cluster
        let testCluster = try await ecsClient.createCluster(input: CreateClusterInput(clusterName: clusterName))
        guard let testClusterName = testCluster.cluster?.clusterName else {
            XCTFail("Cluster could not be created!")
            return
        }
        
        // setup container
        guard let accountId = try await getAccountId() else {
            XCTFail("Couldn't retrieve account id from STS!")
            return
        }
        let containerDefinition = getTestContainerDefinition(accountId: accountId)
        
        // register the task definition
        let taskDefinition = getTestTaskDefinitionInput(container: containerDefinition)
        guard let createdTaskArn = try await registerTaskDefinition(ecsClient, taskDefinition: taskDefinition) else {
            XCTFail("Couldn't register task definition!")
            return
        }
        taskDefArn = createdTaskArn
        
        // run the task directly without creating a service
        let runTaskResp = try await ecsClient.runTask(input: RunTaskInput(
            cluster: testClusterName,
            count: 1,
            launchType: .fargate,
            networkConfiguration: networkingConfig,
            taskDefinition: taskDefArn
        ))
        guard let tasks = runTaskResp.tasks, !tasks.isEmpty else {
            XCTFail("Failed to run task")
            return
        }
        
        // there should only be one since we specified count: 1
        let taskArns = tasks.compactMap { $0.taskArn }
        
        // wait for task to complete, check every 30 seconds
        try await waitForTaskToComplete(ecsClient, clusterName: testClusterName, tasks: taskArns, intervalSeconds: 30)
        
        // check logs for "Success!"
        let logsContainKeyword = try await checkLogsForKeyword(keyword: "Success!")
        XCTAssertTrue(logsContainKeyword, "Logs did not contain the expected keyword. Test failed!")
    }
    
    override func tearDown() async throws {
        // clean up resources
        let ecsClient = try await ECSClient()

        // degregister task definition
        _ = try await ecsClient.deregisterTaskDefinition(input: DeregisterTaskDefinitionInput(
            taskDefinition: taskDefArn
        ))
        
        // delete cluster
        _ = try await ecsClient.deleteCluster(input: DeleteClusterInput(
            cluster: clusterName
        ))
    }
    
    private func getAccountId() async throws -> String? {
        let stsClient = try await STSClient()
        let stsResp = try await stsClient.getCallerIdentity(input: GetCallerIdentityInput())
        return stsResp.account
    }
    
    private func setupIAMRolesAndPolicies() async throws {
        // Create IAM Role and Trust Policy
        let iamClient = try await IAMClient()
        
        // create a trust policy and allows ecs to assume role
        let trustPolicyJSON = """
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Service": "ecs-tasks.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }
        """
        
        taskRoleArn = try await createRole(iamClient, policy: trustPolicyJSON, roleName: taskRoleName)
        
        try await attachPolicy(
            iamClient,
            policyArn: "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
            roleName: taskRoleName
        )
        
        executionRoleArn = try await createRole(iamClient, policy: trustPolicyJSON, roleName: executionRoleName)

        try await attachPolicy(
            iamClient,
            policyArn: "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
            roleName: executionRoleName
        )
    }
    
    private func setupCloudwatchLogs() async throws {
        // create cloudwatch log group if it doesn't exist
        let logsClient = try await CloudWatchLogsClient()
        let describeLogGroupsOutput = try await logsClient.describeLogGroups(input: DescribeLogGroupsInput(
            logGroupNamePrefix: logGroupName
        ))
        if describeLogGroupsOutput.logGroups?.isEmpty ?? true {
            _ = try await logsClient.createLogGroup(input: CreateLogGroupInput(
                logGroupName: logGroupName
            ))
            print("Created log group \(logGroupName)")
        } else {
            print("Log group \(logGroupName) already exists")
        }
    }
    
    private func setupNetworkingConfig(securityGroupNames: [String], availabilityZones: [String]) async throws {
        // create an ec2 client for getting security group and subnet
        let ec2Client = try await EC2Client()

        // get default security group
        let describeSecurityGroupsResp = try await ec2Client.describeSecurityGroups(input: DescribeSecurityGroupsInput(
            groupNames: securityGroupNames
        ))
        guard let defaultSecurityGroupId = describeSecurityGroupsResp.securityGroups?.first?.groupId else {
            XCTFail("Could not retrieve the default security group!")
            return
        }
        
        // get subnets
        let describeSubnetsResponse = try await ec2Client.describeSubnets(input: DescribeSubnetsInput(
            filters: [EC2ClientTypes.Filter(name: "availability-zone", values: availabilityZones)]
        ))
        guard let foundSubnets = describeSubnetsResponse.subnets else {
            XCTFail("Could not retrieve subnets!")
            return
        }
        let subnetIds = foundSubnets.compactMap { $0.subnetId }
        
        networkingConfig = ECSClientTypes.NetworkConfiguration(
            awsvpcConfiguration: ECSClientTypes.AwsVpcConfiguration(
                assignPublicIp: .enabled,
                securityGroups: [defaultSecurityGroupId],
                subnets: subnetIds
            )
        )
    }
    
    private func getTestContainerDefinition(accountId: String) -> ECSClientTypes.ContainerDefinition {
        // Create container def that points to ECR repo
        return ECSClientTypes.ContainerDefinition(
            cpu: 256,
            image: "\(accountId).dkr.ecr.us-east-1.amazonaws.com/ecs-integ-test:latest",
            logConfiguration: ECSClientTypes.LogConfiguration(
                logDriver: .awslogs,
                options: [
                    "awslogs-group": logGroupName,
                    "awslogs-region": "us-east-1",
                    "awslogs-stream-prefix": "ecs"
                ]
            ),
            memory: 512,
            name: "ecs-integ-test-container"
        )
    }
    
    private func getTestTaskDefinitionInput(container: ECSClientTypes.ContainerDefinition) -> RegisterTaskDefinitionInput {
        return RegisterTaskDefinitionInput(
            containerDefinitions: [container],
            cpu: "256",
            executionRoleArn: executionRoleArn,
            family: taskFamilyName,
            memory: "512",
            networkMode: .awsvpc,
            requiresCompatibilities: [.fargate],
            runtimePlatform: ECSClientTypes.RuntimePlatform(
                cpuArchitecture: ECSClientTypes.CPUArchitecture.arm64
            ),
            taskRoleArn: taskRoleArn
        )
    }
    
    private func registerTaskDefinition(_ ecsClient: ECSClient, taskDefinition: RegisterTaskDefinitionInput) async throws -> String? {
        let registerTaskDefResp = try await ecsClient.registerTaskDefinition(input: taskDefinition)
        return registerTaskDefResp.taskDefinition?.taskDefinitionArn
    }
    
    private func getCreateServiceInput(clusterName: String, taskDefinitionArn: String) -> CreateServiceInput {
        return CreateServiceInput(
            cluster: clusterName,
            desiredCount: 1,
            launchType: .fargate,
            networkConfiguration: networkingConfig,
            serviceName: serviceName,
            taskDefinition: taskDefinitionArn
        )
    }
    
    private func createRole(_ iamClient: IAMClient, policy: String, roleName: String) async throws -> String? {
        if let existingRoleArn = try await getRole(iamClient, roleName: roleName) {
            return existingRoleArn
        }
        return try await createNewRole(iamClient, roleName: roleName, policy: policy)
    }

    private func getRole(_ iamClient: IAMClient, roleName: String) async throws -> String? {
        let fetchRoleResp = try await iamClient.getRole(input: GetRoleInput(roleName: roleName))
        return fetchRoleResp.role?.arn
    }

    private func createNewRole(_ iamClient: IAMClient, roleName: String, policy: String) async throws -> String? {
        let createRoleResp = try await iamClient.createRole(input: CreateRoleInput(
            assumeRolePolicyDocument: policy,
            roleName: roleName
        ))
        return createRoleResp.role?.arn
    }

    private func attachPolicy(_ iamClient: IAMClient, policyArn: String, roleName: String) async throws {
        do {
            _ = try await iamClient.attachRolePolicy(input: AttachRolePolicyInput(
                policyArn: policyArn,
                roleName: roleName
            ))
        } catch {
            print("Error occurred while attaching policy")
        }
    }
    
    private func waitForTaskToComplete(_ ecsClient: ECSClient, clusterName: String, tasks: [String], intervalSeconds: UInt64) async throws {
        var isTaskCompleted = false
        while !isTaskCompleted {
            let describeTasksResp = try await ecsClient.describeTasks(input: DescribeTasksInput(cluster: clusterName, tasks: tasks))
            if let task = describeTasksResp.tasks?.first, task.lastStatus == "STOPPED" {
                isTaskCompleted = true
            }
            try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000) // Sleep for X seconds before retrying
        }
    }
    
    private func checkLogsForKeyword(keyword: String) async throws -> Bool {
        let logsClient = try await CloudWatchLogsClient()
        let logStreamsResp = try await logsClient.describeLogStreams(input: DescribeLogStreamsInput(
            descending: true,
            logGroupName: logGroupName,
            orderBy: .lasteventtime
        ))
        
        if let logStreamName = logStreamsResp.logStreams?.first?.logStreamName {
            let logEventsResp = try await logsClient.getLogEvents(input: GetLogEventsInput(
                logGroupName: logGroupName,
                logStreamName: logStreamName
            ))
            
            print("Log Group name: \(logGroupName)")
            print("Log Stream name: \(logStreamName)")
            
            for event in logEventsResp.events ?? [] {
                if let message = event.message, message.contains(keyword) {
                    return true
                }
            }
        }
        return false
    }
    
    private func waitForServiceTasksToDrain(_ ecsClient: ECSClient, clusterName: String, serviceName: String, intervalSeconds: UInt64 = 10) async throws {
        var allTasksStopped = false
        while !allTasksStopped {
            let serviceDescription = try await ecsClient.describeServices(input: DescribeServicesInput(
                cluster: clusterName,
                services: [serviceName]
            ))
            
            if let service = serviceDescription.services?.first, service.runningCount == 0 {
                allTasksStopped = true
            }
            
            if !allTasksStopped {
                try await Task.sleep(nanoseconds: intervalSeconds * 1_000_000_000) // Sleep for X seconds before retrying
            }
        }
    }
}
