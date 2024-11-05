//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension SecretsManagerClient {
    /// Paginate over `[BatchGetSecretValueOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[BatchGetSecretValueInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `BatchGetSecretValueOutput`
    public func batchGetSecretValuePaginated(input: BatchGetSecretValueInput) -> ClientRuntime.PaginatorSequence<BatchGetSecretValueInput, BatchGetSecretValueOutput> {
        return ClientRuntime.PaginatorSequence<BatchGetSecretValueInput, BatchGetSecretValueOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.batchGetSecretValue(input:))
    }
}

extension BatchGetSecretValueInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> BatchGetSecretValueInput {
        return BatchGetSecretValueInput(
            filters: self.filters,
            maxResults: self.maxResults,
            nextToken: token,
            secretIdList: self.secretIdList
        )}
}
extension SecretsManagerClient {
    /// Paginate over `[ListSecretsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSecretsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSecretsOutput`
    public func listSecretsPaginated(input: ListSecretsInput) -> ClientRuntime.PaginatorSequence<ListSecretsInput, ListSecretsOutput> {
        return ClientRuntime.PaginatorSequence<ListSecretsInput, ListSecretsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSecrets(input:))
    }
}

extension ListSecretsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSecretsInput {
        return ListSecretsInput(
            filters: self.filters,
            includePlannedDeletion: self.includePlannedDeletion,
            maxResults: self.maxResults,
            nextToken: token,
            sortOrder: self.sortOrder
        )}
}
extension SecretsManagerClient {
    /// Paginate over `[ListSecretVersionIdsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSecretVersionIdsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSecretVersionIdsOutput`
    public func listSecretVersionIdsPaginated(input: ListSecretVersionIdsInput) -> ClientRuntime.PaginatorSequence<ListSecretVersionIdsInput, ListSecretVersionIdsOutput> {
        return ClientRuntime.PaginatorSequence<ListSecretVersionIdsInput, ListSecretVersionIdsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSecretVersionIds(input:))
    }
}

extension ListSecretVersionIdsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSecretVersionIdsInput {
        return ListSecretVersionIdsInput(
            includeDeprecated: self.includeDeprecated,
            maxResults: self.maxResults,
            nextToken: token,
            secretId: self.secretId
        )}
}