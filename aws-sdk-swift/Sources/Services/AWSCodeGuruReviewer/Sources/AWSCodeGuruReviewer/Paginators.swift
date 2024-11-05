//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension CodeGuruReviewerClient {
    /// Paginate over `[ListCodeReviewsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListCodeReviewsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListCodeReviewsOutput`
    public func listCodeReviewsPaginated(input: ListCodeReviewsInput) -> ClientRuntime.PaginatorSequence<ListCodeReviewsInput, ListCodeReviewsOutput> {
        return ClientRuntime.PaginatorSequence<ListCodeReviewsInput, ListCodeReviewsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listCodeReviews(input:))
    }
}

extension ListCodeReviewsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListCodeReviewsInput {
        return ListCodeReviewsInput(
            maxResults: self.maxResults,
            nextToken: token,
            providerTypes: self.providerTypes,
            repositoryNames: self.repositoryNames,
            states: self.states,
            type: self.type
        )}
}
extension CodeGuruReviewerClient {
    /// Paginate over `[ListRecommendationFeedbackOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListRecommendationFeedbackInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListRecommendationFeedbackOutput`
    public func listRecommendationFeedbackPaginated(input: ListRecommendationFeedbackInput) -> ClientRuntime.PaginatorSequence<ListRecommendationFeedbackInput, ListRecommendationFeedbackOutput> {
        return ClientRuntime.PaginatorSequence<ListRecommendationFeedbackInput, ListRecommendationFeedbackOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listRecommendationFeedback(input:))
    }
}

extension ListRecommendationFeedbackInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListRecommendationFeedbackInput {
        return ListRecommendationFeedbackInput(
            codeReviewArn: self.codeReviewArn,
            maxResults: self.maxResults,
            nextToken: token,
            recommendationIds: self.recommendationIds,
            userIds: self.userIds
        )}
}
extension CodeGuruReviewerClient {
    /// Paginate over `[ListRecommendationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListRecommendationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListRecommendationsOutput`
    public func listRecommendationsPaginated(input: ListRecommendationsInput) -> ClientRuntime.PaginatorSequence<ListRecommendationsInput, ListRecommendationsOutput> {
        return ClientRuntime.PaginatorSequence<ListRecommendationsInput, ListRecommendationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listRecommendations(input:))
    }
}

extension ListRecommendationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListRecommendationsInput {
        return ListRecommendationsInput(
            codeReviewArn: self.codeReviewArn,
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension CodeGuruReviewerClient {
    /// Paginate over `[ListRepositoryAssociationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListRepositoryAssociationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListRepositoryAssociationsOutput`
    public func listRepositoryAssociationsPaginated(input: ListRepositoryAssociationsInput) -> ClientRuntime.PaginatorSequence<ListRepositoryAssociationsInput, ListRepositoryAssociationsOutput> {
        return ClientRuntime.PaginatorSequence<ListRepositoryAssociationsInput, ListRepositoryAssociationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listRepositoryAssociations(input:))
    }
}

extension ListRepositoryAssociationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListRepositoryAssociationsInput {
        return ListRepositoryAssociationsInput(
            maxResults: self.maxResults,
            names: self.names,
            nextToken: token,
            owners: self.owners,
            providerTypes: self.providerTypes,
            states: self.states
        )}
}

extension PaginatorSequence where OperationStackInput == ListRepositoryAssociationsInput, OperationStackOutput == ListRepositoryAssociationsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listRepositoryAssociationsPaginated`
    /// to access the nested member `[CodeGuruReviewerClientTypes.RepositoryAssociationSummary]`
    /// - Returns: `[CodeGuruReviewerClientTypes.RepositoryAssociationSummary]`
    public func repositoryAssociationSummaries() async throws -> [CodeGuruReviewerClientTypes.RepositoryAssociationSummary] {
        return try await self.asyncCompactMap { item in item.repositoryAssociationSummaries }
    }
}