//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension SWFClient {
    /// Paginate over `[GetWorkflowExecutionHistoryOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[GetWorkflowExecutionHistoryInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `GetWorkflowExecutionHistoryOutput`
    public func getWorkflowExecutionHistoryPaginated(input: GetWorkflowExecutionHistoryInput) -> ClientRuntime.PaginatorSequence<GetWorkflowExecutionHistoryInput, GetWorkflowExecutionHistoryOutput> {
        return ClientRuntime.PaginatorSequence<GetWorkflowExecutionHistoryInput, GetWorkflowExecutionHistoryOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.getWorkflowExecutionHistory(input:))
    }
}

extension GetWorkflowExecutionHistoryInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> GetWorkflowExecutionHistoryInput {
        return GetWorkflowExecutionHistoryInput(
            domain: self.domain,
            execution: self.execution,
            maximumPageSize: self.maximumPageSize,
            nextPageToken: token,
            reverseOrder: self.reverseOrder
        )}
}

extension PaginatorSequence where OperationStackInput == GetWorkflowExecutionHistoryInput, OperationStackOutput == GetWorkflowExecutionHistoryOutput {
    /// This paginator transforms the `AsyncSequence` returned by `getWorkflowExecutionHistoryPaginated`
    /// to access the nested member `[SWFClientTypes.HistoryEvent]`
    /// - Returns: `[SWFClientTypes.HistoryEvent]`
    public func events() async throws -> [SWFClientTypes.HistoryEvent] {
        return try await self.asyncCompactMap { item in item.events }
    }
}
extension SWFClient {
    /// Paginate over `[ListActivityTypesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListActivityTypesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListActivityTypesOutput`
    public func listActivityTypesPaginated(input: ListActivityTypesInput) -> ClientRuntime.PaginatorSequence<ListActivityTypesInput, ListActivityTypesOutput> {
        return ClientRuntime.PaginatorSequence<ListActivityTypesInput, ListActivityTypesOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.listActivityTypes(input:))
    }
}

extension ListActivityTypesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListActivityTypesInput {
        return ListActivityTypesInput(
            domain: self.domain,
            maximumPageSize: self.maximumPageSize,
            name: self.name,
            nextPageToken: token,
            registrationStatus: self.registrationStatus,
            reverseOrder: self.reverseOrder
        )}
}

extension PaginatorSequence where OperationStackInput == ListActivityTypesInput, OperationStackOutput == ListActivityTypesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listActivityTypesPaginated`
    /// to access the nested member `[SWFClientTypes.ActivityTypeInfo]`
    /// - Returns: `[SWFClientTypes.ActivityTypeInfo]`
    public func typeInfos() async throws -> [SWFClientTypes.ActivityTypeInfo] {
        return try await self.asyncCompactMap { item in item.typeInfos }
    }
}
extension SWFClient {
    /// Paginate over `[ListClosedWorkflowExecutionsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListClosedWorkflowExecutionsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListClosedWorkflowExecutionsOutput`
    public func listClosedWorkflowExecutionsPaginated(input: ListClosedWorkflowExecutionsInput) -> ClientRuntime.PaginatorSequence<ListClosedWorkflowExecutionsInput, ListClosedWorkflowExecutionsOutput> {
        return ClientRuntime.PaginatorSequence<ListClosedWorkflowExecutionsInput, ListClosedWorkflowExecutionsOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.listClosedWorkflowExecutions(input:))
    }
}

extension ListClosedWorkflowExecutionsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListClosedWorkflowExecutionsInput {
        return ListClosedWorkflowExecutionsInput(
            closeStatusFilter: self.closeStatusFilter,
            closeTimeFilter: self.closeTimeFilter,
            domain: self.domain,
            executionFilter: self.executionFilter,
            maximumPageSize: self.maximumPageSize,
            nextPageToken: token,
            reverseOrder: self.reverseOrder,
            startTimeFilter: self.startTimeFilter,
            tagFilter: self.tagFilter,
            typeFilter: self.typeFilter
        )}
}

extension PaginatorSequence where OperationStackInput == ListClosedWorkflowExecutionsInput, OperationStackOutput == ListClosedWorkflowExecutionsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listClosedWorkflowExecutionsPaginated`
    /// to access the nested member `[SWFClientTypes.WorkflowExecutionInfo]`
    /// - Returns: `[SWFClientTypes.WorkflowExecutionInfo]`
    public func executionInfos() async throws -> [SWFClientTypes.WorkflowExecutionInfo] {
        return try await self.asyncCompactMap { item in item.executionInfos }
    }
}
extension SWFClient {
    /// Paginate over `[ListDomainsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListDomainsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListDomainsOutput`
    public func listDomainsPaginated(input: ListDomainsInput) -> ClientRuntime.PaginatorSequence<ListDomainsInput, ListDomainsOutput> {
        return ClientRuntime.PaginatorSequence<ListDomainsInput, ListDomainsOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.listDomains(input:))
    }
}

extension ListDomainsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListDomainsInput {
        return ListDomainsInput(
            maximumPageSize: self.maximumPageSize,
            nextPageToken: token,
            registrationStatus: self.registrationStatus,
            reverseOrder: self.reverseOrder
        )}
}

extension PaginatorSequence where OperationStackInput == ListDomainsInput, OperationStackOutput == ListDomainsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listDomainsPaginated`
    /// to access the nested member `[SWFClientTypes.DomainInfo]`
    /// - Returns: `[SWFClientTypes.DomainInfo]`
    public func domainInfos() async throws -> [SWFClientTypes.DomainInfo] {
        return try await self.asyncCompactMap { item in item.domainInfos }
    }
}
extension SWFClient {
    /// Paginate over `[ListOpenWorkflowExecutionsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListOpenWorkflowExecutionsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListOpenWorkflowExecutionsOutput`
    public func listOpenWorkflowExecutionsPaginated(input: ListOpenWorkflowExecutionsInput) -> ClientRuntime.PaginatorSequence<ListOpenWorkflowExecutionsInput, ListOpenWorkflowExecutionsOutput> {
        return ClientRuntime.PaginatorSequence<ListOpenWorkflowExecutionsInput, ListOpenWorkflowExecutionsOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.listOpenWorkflowExecutions(input:))
    }
}

extension ListOpenWorkflowExecutionsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListOpenWorkflowExecutionsInput {
        return ListOpenWorkflowExecutionsInput(
            domain: self.domain,
            executionFilter: self.executionFilter,
            maximumPageSize: self.maximumPageSize,
            nextPageToken: token,
            reverseOrder: self.reverseOrder,
            startTimeFilter: self.startTimeFilter,
            tagFilter: self.tagFilter,
            typeFilter: self.typeFilter
        )}
}

extension PaginatorSequence where OperationStackInput == ListOpenWorkflowExecutionsInput, OperationStackOutput == ListOpenWorkflowExecutionsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listOpenWorkflowExecutionsPaginated`
    /// to access the nested member `[SWFClientTypes.WorkflowExecutionInfo]`
    /// - Returns: `[SWFClientTypes.WorkflowExecutionInfo]`
    public func executionInfos() async throws -> [SWFClientTypes.WorkflowExecutionInfo] {
        return try await self.asyncCompactMap { item in item.executionInfos }
    }
}
extension SWFClient {
    /// Paginate over `[ListWorkflowTypesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListWorkflowTypesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListWorkflowTypesOutput`
    public func listWorkflowTypesPaginated(input: ListWorkflowTypesInput) -> ClientRuntime.PaginatorSequence<ListWorkflowTypesInput, ListWorkflowTypesOutput> {
        return ClientRuntime.PaginatorSequence<ListWorkflowTypesInput, ListWorkflowTypesOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.listWorkflowTypes(input:))
    }
}

extension ListWorkflowTypesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListWorkflowTypesInput {
        return ListWorkflowTypesInput(
            domain: self.domain,
            maximumPageSize: self.maximumPageSize,
            name: self.name,
            nextPageToken: token,
            registrationStatus: self.registrationStatus,
            reverseOrder: self.reverseOrder
        )}
}

extension PaginatorSequence where OperationStackInput == ListWorkflowTypesInput, OperationStackOutput == ListWorkflowTypesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listWorkflowTypesPaginated`
    /// to access the nested member `[SWFClientTypes.WorkflowTypeInfo]`
    /// - Returns: `[SWFClientTypes.WorkflowTypeInfo]`
    public func typeInfos() async throws -> [SWFClientTypes.WorkflowTypeInfo] {
        return try await self.asyncCompactMap { item in item.typeInfos }
    }
}
extension SWFClient {
    /// Paginate over `[PollForDecisionTaskOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[PollForDecisionTaskInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `PollForDecisionTaskOutput`
    public func pollForDecisionTaskPaginated(input: PollForDecisionTaskInput) -> ClientRuntime.PaginatorSequence<PollForDecisionTaskInput, PollForDecisionTaskOutput> {
        return ClientRuntime.PaginatorSequence<PollForDecisionTaskInput, PollForDecisionTaskOutput>(input: input, inputKey: \.nextPageToken, outputKey: \.nextPageToken, paginationFunction: self.pollForDecisionTask(input:))
    }
}

extension PollForDecisionTaskInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> PollForDecisionTaskInput {
        return PollForDecisionTaskInput(
            domain: self.domain,
            identity: self.identity,
            maximumPageSize: self.maximumPageSize,
            nextPageToken: token,
            reverseOrder: self.reverseOrder,
            startAtPreviousStartedEvent: self.startAtPreviousStartedEvent,
            taskList: self.taskList
        )}
}

extension PaginatorSequence where OperationStackInput == PollForDecisionTaskInput, OperationStackOutput == PollForDecisionTaskOutput {
    /// This paginator transforms the `AsyncSequence` returned by `pollForDecisionTaskPaginated`
    /// to access the nested member `[SWFClientTypes.HistoryEvent]`
    /// - Returns: `[SWFClientTypes.HistoryEvent]`
    public func events() async throws -> [SWFClientTypes.HistoryEvent] {
        return try await self.asyncCompactMap { item in item.events }
    }
}