//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension KendraClient {
    /// Paginate over `[GetSnapshotsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[GetSnapshotsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `GetSnapshotsOutput`
    public func getSnapshotsPaginated(input: GetSnapshotsInput) -> ClientRuntime.PaginatorSequence<GetSnapshotsInput, GetSnapshotsOutput> {
        return ClientRuntime.PaginatorSequence<GetSnapshotsInput, GetSnapshotsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.getSnapshots(input:))
    }
}

extension GetSnapshotsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> GetSnapshotsInput {
        return GetSnapshotsInput(
            indexId: self.indexId,
            interval: self.interval,
            maxResults: self.maxResults,
            metricType: self.metricType,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListAccessControlConfigurationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListAccessControlConfigurationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListAccessControlConfigurationsOutput`
    public func listAccessControlConfigurationsPaginated(input: ListAccessControlConfigurationsInput) -> ClientRuntime.PaginatorSequence<ListAccessControlConfigurationsInput, ListAccessControlConfigurationsOutput> {
        return ClientRuntime.PaginatorSequence<ListAccessControlConfigurationsInput, ListAccessControlConfigurationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listAccessControlConfigurations(input:))
    }
}

extension ListAccessControlConfigurationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListAccessControlConfigurationsInput {
        return ListAccessControlConfigurationsInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListDataSourcesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListDataSourcesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListDataSourcesOutput`
    public func listDataSourcesPaginated(input: ListDataSourcesInput) -> ClientRuntime.PaginatorSequence<ListDataSourcesInput, ListDataSourcesOutput> {
        return ClientRuntime.PaginatorSequence<ListDataSourcesInput, ListDataSourcesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listDataSources(input:))
    }
}

extension ListDataSourcesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListDataSourcesInput {
        return ListDataSourcesInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListDataSourceSyncJobsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListDataSourceSyncJobsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListDataSourceSyncJobsOutput`
    public func listDataSourceSyncJobsPaginated(input: ListDataSourceSyncJobsInput) -> ClientRuntime.PaginatorSequence<ListDataSourceSyncJobsInput, ListDataSourceSyncJobsOutput> {
        return ClientRuntime.PaginatorSequence<ListDataSourceSyncJobsInput, ListDataSourceSyncJobsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listDataSourceSyncJobs(input:))
    }
}

extension ListDataSourceSyncJobsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListDataSourceSyncJobsInput {
        return ListDataSourceSyncJobsInput(
            id: self.id,
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token,
            startTimeFilter: self.startTimeFilter,
            statusFilter: self.statusFilter
        )}
}
extension KendraClient {
    /// Paginate over `[ListEntityPersonasOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListEntityPersonasInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListEntityPersonasOutput`
    public func listEntityPersonasPaginated(input: ListEntityPersonasInput) -> ClientRuntime.PaginatorSequence<ListEntityPersonasInput, ListEntityPersonasOutput> {
        return ClientRuntime.PaginatorSequence<ListEntityPersonasInput, ListEntityPersonasOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listEntityPersonas(input:))
    }
}

extension ListEntityPersonasInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListEntityPersonasInput {
        return ListEntityPersonasInput(
            id: self.id,
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListExperienceEntitiesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListExperienceEntitiesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListExperienceEntitiesOutput`
    public func listExperienceEntitiesPaginated(input: ListExperienceEntitiesInput) -> ClientRuntime.PaginatorSequence<ListExperienceEntitiesInput, ListExperienceEntitiesOutput> {
        return ClientRuntime.PaginatorSequence<ListExperienceEntitiesInput, ListExperienceEntitiesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listExperienceEntities(input:))
    }
}

extension ListExperienceEntitiesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListExperienceEntitiesInput {
        return ListExperienceEntitiesInput(
            id: self.id,
            indexId: self.indexId,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListExperiencesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListExperiencesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListExperiencesOutput`
    public func listExperiencesPaginated(input: ListExperiencesInput) -> ClientRuntime.PaginatorSequence<ListExperiencesInput, ListExperiencesOutput> {
        return ClientRuntime.PaginatorSequence<ListExperiencesInput, ListExperiencesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listExperiences(input:))
    }
}

extension ListExperiencesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListExperiencesInput {
        return ListExperiencesInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListFaqsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListFaqsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListFaqsOutput`
    public func listFaqsPaginated(input: ListFaqsInput) -> ClientRuntime.PaginatorSequence<ListFaqsInput, ListFaqsOutput> {
        return ClientRuntime.PaginatorSequence<ListFaqsInput, ListFaqsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listFaqs(input:))
    }
}

extension ListFaqsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListFaqsInput {
        return ListFaqsInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListGroupsOlderThanOrderingIdOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListGroupsOlderThanOrderingIdInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListGroupsOlderThanOrderingIdOutput`
    public func listGroupsOlderThanOrderingIdPaginated(input: ListGroupsOlderThanOrderingIdInput) -> ClientRuntime.PaginatorSequence<ListGroupsOlderThanOrderingIdInput, ListGroupsOlderThanOrderingIdOutput> {
        return ClientRuntime.PaginatorSequence<ListGroupsOlderThanOrderingIdInput, ListGroupsOlderThanOrderingIdOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listGroupsOlderThanOrderingId(input:))
    }
}

extension ListGroupsOlderThanOrderingIdInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListGroupsOlderThanOrderingIdInput {
        return ListGroupsOlderThanOrderingIdInput(
            dataSourceId: self.dataSourceId,
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token,
            orderingId: self.orderingId
        )}
}
extension KendraClient {
    /// Paginate over `[ListIndicesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListIndicesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListIndicesOutput`
    public func listIndicesPaginated(input: ListIndicesInput) -> ClientRuntime.PaginatorSequence<ListIndicesInput, ListIndicesOutput> {
        return ClientRuntime.PaginatorSequence<ListIndicesInput, ListIndicesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listIndices(input:))
    }
}

extension ListIndicesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListIndicesInput {
        return ListIndicesInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListQuerySuggestionsBlockListsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListQuerySuggestionsBlockListsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListQuerySuggestionsBlockListsOutput`
    public func listQuerySuggestionsBlockListsPaginated(input: ListQuerySuggestionsBlockListsInput) -> ClientRuntime.PaginatorSequence<ListQuerySuggestionsBlockListsInput, ListQuerySuggestionsBlockListsOutput> {
        return ClientRuntime.PaginatorSequence<ListQuerySuggestionsBlockListsInput, ListQuerySuggestionsBlockListsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listQuerySuggestionsBlockLists(input:))
    }
}

extension ListQuerySuggestionsBlockListsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListQuerySuggestionsBlockListsInput {
        return ListQuerySuggestionsBlockListsInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension KendraClient {
    /// Paginate over `[ListThesauriOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListThesauriInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListThesauriOutput`
    public func listThesauriPaginated(input: ListThesauriInput) -> ClientRuntime.PaginatorSequence<ListThesauriInput, ListThesauriOutput> {
        return ClientRuntime.PaginatorSequence<ListThesauriInput, ListThesauriOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listThesauri(input:))
    }
}

extension ListThesauriInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListThesauriInput {
        return ListThesauriInput(
            indexId: self.indexId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}