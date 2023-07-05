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
    
    var putLogEventsHandler: (PutLogEventsInput) async throws -> PutLogEventsOutputResponse = { input in
        return PutLogEventsOutputResponse()
    }

    func putLogEvents(input: PutLogEventsInput) async throws -> PutLogEventsOutputResponse {
        interactions.append(#function)
        return try await putLogEventsHandler(input)
    }
    
    func associateKmsKey(input: AWSCloudWatchLogs.AssociateKmsKeyInput) async throws -> AWSCloudWatchLogs.AssociateKmsKeyOutputResponse {
        throw MockError.unimplemented
    }
    
    func cancelExportTask(input: AWSCloudWatchLogs.CancelExportTaskInput) async throws -> AWSCloudWatchLogs.CancelExportTaskOutputResponse {
        throw MockError.unimplemented
    }
    
    func createExportTask(input: AWSCloudWatchLogs.CreateExportTaskInput) async throws -> AWSCloudWatchLogs.CreateExportTaskOutputResponse {
        throw MockError.unimplemented
    }
    
    func createLogGroup(input: AWSCloudWatchLogs.CreateLogGroupInput) async throws -> AWSCloudWatchLogs.CreateLogGroupOutputResponse {
        throw MockError.unimplemented
    }
    
    var createLogStreamHandler: (CreateLogStreamInput) async throws -> CreateLogStreamOutputResponse = { _ in
        return CreateLogStreamOutputResponse()
    }
    
    func createLogStream(input: CreateLogStreamInput) async throws -> CreateLogStreamOutputResponse {
        interactions.append(#function)
        return try await createLogStreamHandler(input)
    }
    
    func deleteDestination(input: AWSCloudWatchLogs.DeleteDestinationInput) async throws -> AWSCloudWatchLogs.DeleteDestinationOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteLogGroup(input: AWSCloudWatchLogs.DeleteLogGroupInput) async throws -> AWSCloudWatchLogs.DeleteLogGroupOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteLogStream(input: AWSCloudWatchLogs.DeleteLogStreamInput) async throws -> AWSCloudWatchLogs.DeleteLogStreamOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteMetricFilter(input: AWSCloudWatchLogs.DeleteMetricFilterInput) async throws -> AWSCloudWatchLogs.DeleteMetricFilterOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteQueryDefinition(input: AWSCloudWatchLogs.DeleteQueryDefinitionInput) async throws -> AWSCloudWatchLogs.DeleteQueryDefinitionOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteResourcePolicy(input: AWSCloudWatchLogs.DeleteResourcePolicyInput) async throws -> AWSCloudWatchLogs.DeleteResourcePolicyOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteRetentionPolicy(input: AWSCloudWatchLogs.DeleteRetentionPolicyInput) async throws -> AWSCloudWatchLogs.DeleteRetentionPolicyOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteSubscriptionFilter(input: AWSCloudWatchLogs.DeleteSubscriptionFilterInput) async throws -> AWSCloudWatchLogs.DeleteSubscriptionFilterOutputResponse {
        throw MockError.unimplemented
    }
    
    func deleteDataProtectionPolicy(input: AWSCloudWatchLogs.DeleteDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.DeleteDataProtectionPolicyOutputResponse {
        throw MockError.unexpected
    }
    
    func describeDestinations(input: AWSCloudWatchLogs.DescribeDestinationsInput) async throws -> AWSCloudWatchLogs.DescribeDestinationsOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeExportTasks(input: AWSCloudWatchLogs.DescribeExportTasksInput) async throws -> AWSCloudWatchLogs.DescribeExportTasksOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeLogGroups(input: AWSCloudWatchLogs.DescribeLogGroupsInput) async throws -> AWSCloudWatchLogs.DescribeLogGroupsOutputResponse {
        throw MockError.unimplemented
    }
    
    var describeLogStreamsHandler: (DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutputResponse = { _ in
        return DescribeLogStreamsOutputResponse()
    }

    func describeLogStreams(input: DescribeLogStreamsInput) async throws -> DescribeLogStreamsOutputResponse {
        interactions.append(#function)
        return try await describeLogStreamsHandler(input)
    }
    
    func describeMetricFilters(input: AWSCloudWatchLogs.DescribeMetricFiltersInput) async throws -> AWSCloudWatchLogs.DescribeMetricFiltersOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeQueries(input: AWSCloudWatchLogs.DescribeQueriesInput) async throws -> AWSCloudWatchLogs.DescribeQueriesOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeQueryDefinitions(input: AWSCloudWatchLogs.DescribeQueryDefinitionsInput) async throws -> AWSCloudWatchLogs.DescribeQueryDefinitionsOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeResourcePolicies(input: AWSCloudWatchLogs.DescribeResourcePoliciesInput) async throws -> AWSCloudWatchLogs.DescribeResourcePoliciesOutputResponse {
        throw MockError.unimplemented
    }
    
    func describeSubscriptionFilters(input: AWSCloudWatchLogs.DescribeSubscriptionFiltersInput) async throws -> AWSCloudWatchLogs.DescribeSubscriptionFiltersOutputResponse {
        throw MockError.unimplemented
    }
    
    func disassociateKmsKey(input: AWSCloudWatchLogs.DisassociateKmsKeyInput) async throws -> AWSCloudWatchLogs.DisassociateKmsKeyOutputResponse {
        throw MockError.unimplemented
    }
    
    func filterLogEvents(input: AWSCloudWatchLogs.FilterLogEventsInput) async throws -> AWSCloudWatchLogs.FilterLogEventsOutputResponse {
        throw MockError.unimplemented
    }
    
    func getDataProtectionPolicy(input: AWSCloudWatchLogs.GetDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.GetDataProtectionPolicyOutputResponse {
        throw MockError.unexpected
    }
    
    func getLogEvents(input: AWSCloudWatchLogs.GetLogEventsInput) async throws -> AWSCloudWatchLogs.GetLogEventsOutputResponse {
        throw MockError.unimplemented
    }
    
    func getLogGroupFields(input: AWSCloudWatchLogs.GetLogGroupFieldsInput) async throws -> AWSCloudWatchLogs.GetLogGroupFieldsOutputResponse {
        throw MockError.unimplemented
    }
    
    func getLogRecord(input: AWSCloudWatchLogs.GetLogRecordInput) async throws -> AWSCloudWatchLogs.GetLogRecordOutputResponse {
        throw MockError.unimplemented
    }
    
    func getQueryResults(input: AWSCloudWatchLogs.GetQueryResultsInput) async throws -> AWSCloudWatchLogs.GetQueryResultsOutputResponse {
        throw MockError.unimplemented
    }
    
    func listTagsForResource(input: AWSCloudWatchLogs.ListTagsForResourceInput) async throws -> AWSCloudWatchLogs.ListTagsForResourceOutputResponse {
        throw MockError.unimplemented
    }
    
    func listTagsLogGroup(input: AWSCloudWatchLogs.ListTagsLogGroupInput) async throws -> AWSCloudWatchLogs.ListTagsLogGroupOutputResponse {
        throw MockError.unimplemented
    }
    
    func putDataProtectionPolicy(input: AWSCloudWatchLogs.PutDataProtectionPolicyInput) async throws -> AWSCloudWatchLogs.PutDataProtectionPolicyOutputResponse {
        throw MockError.unexpected
    }

    func putDestination(input: AWSCloudWatchLogs.PutDestinationInput) async throws -> AWSCloudWatchLogs.PutDestinationOutputResponse {
        throw MockError.unimplemented
    }
    
    func putDestinationPolicy(input: AWSCloudWatchLogs.PutDestinationPolicyInput) async throws -> AWSCloudWatchLogs.PutDestinationPolicyOutputResponse {
        throw MockError.unimplemented
    }
    
    func putMetricFilter(input: AWSCloudWatchLogs.PutMetricFilterInput) async throws -> AWSCloudWatchLogs.PutMetricFilterOutputResponse {
        throw MockError.unimplemented
    }
    
    func putQueryDefinition(input: AWSCloudWatchLogs.PutQueryDefinitionInput) async throws -> AWSCloudWatchLogs.PutQueryDefinitionOutputResponse {
        throw MockError.unimplemented
    }
    
    func putResourcePolicy(input: AWSCloudWatchLogs.PutResourcePolicyInput) async throws -> AWSCloudWatchLogs.PutResourcePolicyOutputResponse {
        throw MockError.unimplemented
    }
    
    func putRetentionPolicy(input: AWSCloudWatchLogs.PutRetentionPolicyInput) async throws -> AWSCloudWatchLogs.PutRetentionPolicyOutputResponse {
        throw MockError.unimplemented
    }
    
    func putSubscriptionFilter(input: AWSCloudWatchLogs.PutSubscriptionFilterInput) async throws -> AWSCloudWatchLogs.PutSubscriptionFilterOutputResponse {
        throw MockError.unimplemented
    }
    
    func startQuery(input: AWSCloudWatchLogs.StartQueryInput) async throws -> AWSCloudWatchLogs.StartQueryOutputResponse {
        throw MockError.unimplemented
    }
    
    func stopQuery(input: AWSCloudWatchLogs.StopQueryInput) async throws -> AWSCloudWatchLogs.StopQueryOutputResponse {
        throw MockError.unimplemented
    }
    
    func tagLogGroup(input: AWSCloudWatchLogs.TagLogGroupInput) async throws -> AWSCloudWatchLogs.TagLogGroupOutputResponse {
        throw MockError.unimplemented
    }
    
    func tagResource(input: AWSCloudWatchLogs.TagResourceInput) async throws -> AWSCloudWatchLogs.TagResourceOutputResponse {
        throw MockError.unimplemented
    }
    
    func testMetricFilter(input: AWSCloudWatchLogs.TestMetricFilterInput) async throws -> AWSCloudWatchLogs.TestMetricFilterOutputResponse {
        throw MockError.unimplemented
    }
    
    func untagLogGroup(input: AWSCloudWatchLogs.UntagLogGroupInput) async throws -> AWSCloudWatchLogs.UntagLogGroupOutputResponse {
        throw MockError.unimplemented
    }
    
    func untagResource(input: AWSCloudWatchLogs.UntagResourceInput) async throws -> AWSCloudWatchLogs.UntagResourceOutputResponse {
        throw MockError.unimplemented
    }
    
    
}
