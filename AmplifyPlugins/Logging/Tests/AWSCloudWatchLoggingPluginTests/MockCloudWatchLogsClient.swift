//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCloudWatchLogs
import Foundation

class MockCloudWatchLogsClient: CloudWatchLogsClientProtocol {
    
    enum MockError: Error {
        case unexpected
        case unimplemented
    }
    
    var interactions: [String] = []
    
    var putLogEventsHandler: (PutLogEventsInput) async throws -> PutLogEventsOutput = { input in
        return PutLogEventsOutput()
    }

    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutput {
        interactions.append(#function)
        return try await putLogEventsHandler(input)
    }
    
    func associateKmsKey(input: AWSCloudWatchLogs.AssociateKmsKeyInput) async throws -> AWSCloudWatchLogs.AssociateKmsKeyOutput {
        throw MockError.unimplemented
    }
    
    func cancelExportTask(input: AWSCloudWatchLogs.CancelExportTaskInput) async throws -> AWSCloudWatchLogs.CancelExportTaskOutput {
        throw MockError.unimplemented
    }
    
    func createExportTask(input: AWSCloudWatchLogs.CreateExportTaskInput) async throws -> AWSCloudWatchLogs.CreateExportTaskOutput {
        throw MockError.unimplemented
    }
    
    func createLogGroup(input: AWSCloudWatchLogs.CreateLogGroupInput) async throws -> AWSCloudWatchLogs.CreateLogGroupOutput {
        throw MockError.unimplemented
    }
    
    var createLogStreamHandler: (CreateLogStreamInput) async throws -> CreateLogStreamOutput = { _ in
        return CreateLogStreamOutput()
    }
    
    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutput {
        interactions.append(#function)
        return try await createLogStreamHandler(input)
    }
    
    func deleteDestination(input: AWSCloudWatchLogs.DeleteDestinationInput) async throws -> AWSCloudWatchLogs.DeleteDestinationOutput {
        throw MockError.unimplemented
    }
    
    func deleteLogGroup(input: AWSCloudWatchLogs.DeleteLogGroupInput) async throws -> AWSCloudWatchLogs.DeleteLogGroupOutput {
        throw MockError.unimplemented
    }
    
    func deleteLogStream(input: AWSCloudWatchLogs.DeleteLogStreamInput) async throws -> AWSCloudWatchLogs.DeleteLogStreamOutput {
        throw MockError.unimplemented
    }
    
    func deleteMetricFilter(input: AWSCloudWatchLogs.DeleteMetricFilterInput) async throws -> AWSCloudWatchLogs.DeleteMetricFilterOutput {
        throw MockError.unimplemented
    }
    
    func deleteQueryDefinition(input: AWSCloudWatchLogs.DeleteQueryDefinitionInput) async throws -> AWSCloudWatchLogs.DeleteQueryDefinitionOutput {
        throw MockError.unimplemented
    }
    
    func deleteResourcePolicy(input: AWSCloudWatchLogs.DeleteResourcePolicyInput) async throws -> AWSCloudWatchLogs.DeleteResourcePolicyOutput {
        throw MockError.unimplemented
    }
    
    func deleteRetentionPolicy(input: AWSCloudWatchLogs.DeleteRetentionPolicyInput) async throws -> AWSCloudWatchLogs.DeleteRetentionPolicyOutput {
        throw MockError.unimplemented
    }
    
    func deleteSubscriptionFilter(input: AWSCloudWatchLogs.DeleteSubscriptionFilterInput) async throws -> AWSCloudWatchLogs.DeleteSubscriptionFilterOutput {
        throw MockError.unimplemented
    }
    
    func deleteDataProtectionPolicy(input: AWSCloudWatchLogs.DeleteDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.DeleteDataProtectionPolicyOutput {
        throw MockError.unexpected
    }
    
    func describeDestinations(input: AWSCloudWatchLogs.DescribeDestinationsInput) async throws -> AWSCloudWatchLogs.DescribeDestinationsOutput {
        throw MockError.unimplemented
    }
    
    func describeExportTasks(input: AWSCloudWatchLogs.DescribeExportTasksInput) async throws -> AWSCloudWatchLogs.DescribeExportTasksOutput {
        throw MockError.unimplemented
    }
    
    func describeLogGroups(input: AWSCloudWatchLogs.DescribeLogGroupsInput) async throws -> AWSCloudWatchLogs.DescribeLogGroupsOutput {
        throw MockError.unimplemented
    }
    
    var describeLogStreamsHandler: (DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput = { _ in
        return DescribeLogStreamsOutput()
    }

    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutput {
        interactions.append(#function)
        return try await describeLogStreamsHandler(input)
    }
    
    func describeMetricFilters(input: AWSCloudWatchLogs.DescribeMetricFiltersInput) async throws -> AWSCloudWatchLogs.DescribeMetricFiltersOutput {
        throw MockError.unimplemented
    }
    
    func describeQueries(input: AWSCloudWatchLogs.DescribeQueriesInput) async throws -> AWSCloudWatchLogs.DescribeQueriesOutput {
        throw MockError.unimplemented
    }
    
    func describeQueryDefinitions(input: AWSCloudWatchLogs.DescribeQueryDefinitionsInput) async throws -> AWSCloudWatchLogs.DescribeQueryDefinitionsOutput {
        throw MockError.unimplemented
    }
    
    func describeResourcePolicies(input: AWSCloudWatchLogs.DescribeResourcePoliciesInput) async throws -> AWSCloudWatchLogs.DescribeResourcePoliciesOutput {
        throw MockError.unimplemented
    }
    
    func describeSubscriptionFilters(input: AWSCloudWatchLogs.DescribeSubscriptionFiltersInput) async throws -> AWSCloudWatchLogs.DescribeSubscriptionFiltersOutput {
        throw MockError.unimplemented
    }
    
    func disassociateKmsKey(input: AWSCloudWatchLogs.DisassociateKmsKeyInput) async throws -> AWSCloudWatchLogs.DisassociateKmsKeyOutput {
        throw MockError.unimplemented
    }
    
    func filterLogEvents(input: AWSCloudWatchLogs.FilterLogEventsInput) async throws -> AWSCloudWatchLogs.FilterLogEventsOutput {
        throw MockError.unimplemented
    }
    
    func getDataProtectionPolicy(input: AWSCloudWatchLogs.GetDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.GetDataProtectionPolicyOutput {
        throw MockError.unexpected
    }
    
    func getLogEvents(input: AWSCloudWatchLogs.GetLogEventsInput) async throws -> AWSCloudWatchLogs.GetLogEventsOutput {
        throw MockError.unimplemented
    }
    
    func getLogGroupFields(input: AWSCloudWatchLogs.GetLogGroupFieldsInput) async throws -> AWSCloudWatchLogs.GetLogGroupFieldsOutput {
        throw MockError.unimplemented
    }
    
    func getLogRecord(input: AWSCloudWatchLogs.GetLogRecordInput) async throws -> AWSCloudWatchLogs.GetLogRecordOutput {
        throw MockError.unimplemented
    }
    
    func getQueryResults(input: AWSCloudWatchLogs.GetQueryResultsInput) async throws -> AWSCloudWatchLogs.GetQueryResultsOutput {
        throw MockError.unimplemented
    }
    
    func listTagsForResource(input: AWSCloudWatchLogs.ListTagsForResourceInput) async throws -> AWSCloudWatchLogs.ListTagsForResourceOutput {
        throw MockError.unimplemented
    }
    
    func listTagsLogGroup(input: AWSCloudWatchLogs.ListTagsLogGroupInput) async throws -> AWSCloudWatchLogs.ListTagsLogGroupOutput {
        throw MockError.unimplemented
    }
    
    func putDataProtectionPolicy(input: AWSCloudWatchLogs.PutDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.PutDataProtectionPolicyOutput {
        throw MockError.unexpected
    }

    func putDestination(input: AWSCloudWatchLogs.PutDestinationInput) async throws -> AWSCloudWatchLogs.PutDestinationOutput {
        throw MockError.unimplemented
    }
    
    func putDestinationPolicy(input: AWSCloudWatchLogs.PutDestinationPolicyInput) async throws -> AWSCloudWatchLogs.PutDestinationPolicyOutput {
        throw MockError.unimplemented
    }
    
    func putMetricFilter(input: AWSCloudWatchLogs.PutMetricFilterInput) async throws -> AWSCloudWatchLogs.PutMetricFilterOutput {
        throw MockError.unimplemented
    }
    
    func putQueryDefinition(input: AWSCloudWatchLogs.PutQueryDefinitionInput) async throws -> AWSCloudWatchLogs.PutQueryDefinitionOutput {
        throw MockError.unimplemented
    }
    
    func putResourcePolicy(input: AWSCloudWatchLogs.PutResourcePolicyInput) async throws -> AWSCloudWatchLogs.PutResourcePolicyOutput {
        throw MockError.unimplemented
    }
    
    func putRetentionPolicy(input: AWSCloudWatchLogs.PutRetentionPolicyInput) async throws -> AWSCloudWatchLogs.PutRetentionPolicyOutput {
        throw MockError.unimplemented
    }
    
    func putSubscriptionFilter(input: AWSCloudWatchLogs.PutSubscriptionFilterInput) async throws -> AWSCloudWatchLogs.PutSubscriptionFilterOutput {
        throw MockError.unimplemented
    }
    
    func startQuery(input: AWSCloudWatchLogs.StartQueryInput) async throws -> AWSCloudWatchLogs.StartQueryOutput {
        throw MockError.unimplemented
    }
    
    func stopQuery(input: AWSCloudWatchLogs.StopQueryInput) async throws -> AWSCloudWatchLogs.StopQueryOutput {
        throw MockError.unimplemented
    }
    
    func tagLogGroup(input: AWSCloudWatchLogs.TagLogGroupInput) async throws -> AWSCloudWatchLogs.TagLogGroupOutput {
        throw MockError.unimplemented
    }
    
    func tagResource(input: AWSCloudWatchLogs.TagResourceInput) async throws -> AWSCloudWatchLogs.TagResourceOutput {
        throw MockError.unimplemented
    }
    
    func testMetricFilter(input: AWSCloudWatchLogs.TestMetricFilterInput) async throws -> AWSCloudWatchLogs.TestMetricFilterOutput {
        throw MockError.unimplemented
    }
    
    func untagLogGroup(input: AWSCloudWatchLogs.UntagLogGroupInput) async throws -> AWSCloudWatchLogs.UntagLogGroupOutput {
        throw MockError.unimplemented
    }
    
    func untagResource(input: AWSCloudWatchLogs.UntagResourceInput) async throws -> AWSCloudWatchLogs.UntagResourceOutput {
        throw MockError.unimplemented
    }
    
    func deleteAccountPolicy(input: AWSCloudWatchLogs.DeleteAccountPolicyInput) async throws -> AWSCloudWatchLogs.DeleteAccountPolicyOutput {
        throw MockError.unimplemented
    }

    func describeAccountPolicies(input: AWSCloudWatchLogs.DescribeAccountPoliciesInput) async throws -> AWSCloudWatchLogs.DescribeAccountPoliciesOutput {
        throw MockError.unimplemented
    }

    func putAccountPolicy(input: AWSCloudWatchLogs.PutAccountPolicyInput) async throws -> AWSCloudWatchLogs.PutAccountPolicyOutput {
        throw MockError.unimplemented
    }
}
