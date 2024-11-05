//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension CostExplorerClient {
    /// Paginate over `[GetSavingsPlansCoverageOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[GetSavingsPlansCoverageInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `GetSavingsPlansCoverageOutput`
    public func getSavingsPlansCoveragePaginated(input: GetSavingsPlansCoverageInput) -> ClientRuntime.PaginatorSequence<GetSavingsPlansCoverageInput, GetSavingsPlansCoverageOutput> {
        return ClientRuntime.PaginatorSequence<GetSavingsPlansCoverageInput, GetSavingsPlansCoverageOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.getSavingsPlansCoverage(input:))
    }
}

extension GetSavingsPlansCoverageInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> GetSavingsPlansCoverageInput {
        return GetSavingsPlansCoverageInput(
            filter: self.filter,
            granularity: self.granularity,
            groupBy: self.groupBy,
            maxResults: self.maxResults,
            metrics: self.metrics,
            nextToken: token,
            sortBy: self.sortBy,
            timePeriod: self.timePeriod
        )}
}
extension CostExplorerClient {
    /// Paginate over `[GetSavingsPlansUtilizationDetailsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[GetSavingsPlansUtilizationDetailsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `GetSavingsPlansUtilizationDetailsOutput`
    public func getSavingsPlansUtilizationDetailsPaginated(input: GetSavingsPlansUtilizationDetailsInput) -> ClientRuntime.PaginatorSequence<GetSavingsPlansUtilizationDetailsInput, GetSavingsPlansUtilizationDetailsOutput> {
        return ClientRuntime.PaginatorSequence<GetSavingsPlansUtilizationDetailsInput, GetSavingsPlansUtilizationDetailsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.getSavingsPlansUtilizationDetails(input:))
    }
}

extension GetSavingsPlansUtilizationDetailsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> GetSavingsPlansUtilizationDetailsInput {
        return GetSavingsPlansUtilizationDetailsInput(
            dataType: self.dataType,
            filter: self.filter,
            maxResults: self.maxResults,
            nextToken: token,
            sortBy: self.sortBy,
            timePeriod: self.timePeriod
        )}
}
extension CostExplorerClient {
    /// Paginate over `[ListCostAllocationTagBackfillHistoryOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListCostAllocationTagBackfillHistoryInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListCostAllocationTagBackfillHistoryOutput`
    public func listCostAllocationTagBackfillHistoryPaginated(input: ListCostAllocationTagBackfillHistoryInput) -> ClientRuntime.PaginatorSequence<ListCostAllocationTagBackfillHistoryInput, ListCostAllocationTagBackfillHistoryOutput> {
        return ClientRuntime.PaginatorSequence<ListCostAllocationTagBackfillHistoryInput, ListCostAllocationTagBackfillHistoryOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listCostAllocationTagBackfillHistory(input:))
    }
}

extension ListCostAllocationTagBackfillHistoryInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListCostAllocationTagBackfillHistoryInput {
        return ListCostAllocationTagBackfillHistoryInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension CostExplorerClient {
    /// Paginate over `[ListCostAllocationTagsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListCostAllocationTagsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListCostAllocationTagsOutput`
    public func listCostAllocationTagsPaginated(input: ListCostAllocationTagsInput) -> ClientRuntime.PaginatorSequence<ListCostAllocationTagsInput, ListCostAllocationTagsOutput> {
        return ClientRuntime.PaginatorSequence<ListCostAllocationTagsInput, ListCostAllocationTagsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listCostAllocationTags(input:))
    }
}

extension ListCostAllocationTagsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListCostAllocationTagsInput {
        return ListCostAllocationTagsInput(
            maxResults: self.maxResults,
            nextToken: token,
            status: self.status,
            tagKeys: self.tagKeys,
            type: self.type
        )}
}
extension CostExplorerClient {
    /// Paginate over `[ListCostCategoryDefinitionsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListCostCategoryDefinitionsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListCostCategoryDefinitionsOutput`
    public func listCostCategoryDefinitionsPaginated(input: ListCostCategoryDefinitionsInput) -> ClientRuntime.PaginatorSequence<ListCostCategoryDefinitionsInput, ListCostCategoryDefinitionsOutput> {
        return ClientRuntime.PaginatorSequence<ListCostCategoryDefinitionsInput, ListCostCategoryDefinitionsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listCostCategoryDefinitions(input:))
    }
}

extension ListCostCategoryDefinitionsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListCostCategoryDefinitionsInput {
        return ListCostCategoryDefinitionsInput(
            effectiveOn: self.effectiveOn,
            maxResults: self.maxResults,
            nextToken: token
        )}
}