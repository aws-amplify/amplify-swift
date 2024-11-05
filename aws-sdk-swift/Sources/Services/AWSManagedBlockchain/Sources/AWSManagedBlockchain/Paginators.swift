//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension ManagedBlockchainClient {
    /// Paginate over `[ListAccessorsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListAccessorsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListAccessorsOutput`
    public func listAccessorsPaginated(input: ListAccessorsInput) -> ClientRuntime.PaginatorSequence<ListAccessorsInput, ListAccessorsOutput> {
        return ClientRuntime.PaginatorSequence<ListAccessorsInput, ListAccessorsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listAccessors(input:))
    }
}

extension ListAccessorsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListAccessorsInput {
        return ListAccessorsInput(
            maxResults: self.maxResults,
            networkType: self.networkType,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListAccessorsInput, OperationStackOutput == ListAccessorsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listAccessorsPaginated`
    /// to access the nested member `[ManagedBlockchainClientTypes.AccessorSummary]`
    /// - Returns: `[ManagedBlockchainClientTypes.AccessorSummary]`
    public func accessors() async throws -> [ManagedBlockchainClientTypes.AccessorSummary] {
        return try await self.asyncCompactMap { item in item.accessors }
    }
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListInvitationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListInvitationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListInvitationsOutput`
    public func listInvitationsPaginated(input: ListInvitationsInput) -> ClientRuntime.PaginatorSequence<ListInvitationsInput, ListInvitationsOutput> {
        return ClientRuntime.PaginatorSequence<ListInvitationsInput, ListInvitationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listInvitations(input:))
    }
}

extension ListInvitationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListInvitationsInput {
        return ListInvitationsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListMembersOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListMembersInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListMembersOutput`
    public func listMembersPaginated(input: ListMembersInput) -> ClientRuntime.PaginatorSequence<ListMembersInput, ListMembersOutput> {
        return ClientRuntime.PaginatorSequence<ListMembersInput, ListMembersOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listMembers(input:))
    }
}

extension ListMembersInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListMembersInput {
        return ListMembersInput(
            isOwned: self.isOwned,
            maxResults: self.maxResults,
            name: self.name,
            networkId: self.networkId,
            nextToken: token,
            status: self.status
        )}
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListNetworksOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListNetworksInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListNetworksOutput`
    public func listNetworksPaginated(input: ListNetworksInput) -> ClientRuntime.PaginatorSequence<ListNetworksInput, ListNetworksOutput> {
        return ClientRuntime.PaginatorSequence<ListNetworksInput, ListNetworksOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listNetworks(input:))
    }
}

extension ListNetworksInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListNetworksInput {
        return ListNetworksInput(
            framework: self.framework,
            maxResults: self.maxResults,
            name: self.name,
            nextToken: token,
            status: self.status
        )}
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListNodesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListNodesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListNodesOutput`
    public func listNodesPaginated(input: ListNodesInput) -> ClientRuntime.PaginatorSequence<ListNodesInput, ListNodesOutput> {
        return ClientRuntime.PaginatorSequence<ListNodesInput, ListNodesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listNodes(input:))
    }
}

extension ListNodesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListNodesInput {
        return ListNodesInput(
            maxResults: self.maxResults,
            memberId: self.memberId,
            networkId: self.networkId,
            nextToken: token,
            status: self.status
        )}
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListProposalsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListProposalsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListProposalsOutput`
    public func listProposalsPaginated(input: ListProposalsInput) -> ClientRuntime.PaginatorSequence<ListProposalsInput, ListProposalsOutput> {
        return ClientRuntime.PaginatorSequence<ListProposalsInput, ListProposalsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listProposals(input:))
    }
}

extension ListProposalsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListProposalsInput {
        return ListProposalsInput(
            maxResults: self.maxResults,
            networkId: self.networkId,
            nextToken: token
        )}
}
extension ManagedBlockchainClient {
    /// Paginate over `[ListProposalVotesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListProposalVotesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListProposalVotesOutput`
    public func listProposalVotesPaginated(input: ListProposalVotesInput) -> ClientRuntime.PaginatorSequence<ListProposalVotesInput, ListProposalVotesOutput> {
        return ClientRuntime.PaginatorSequence<ListProposalVotesInput, ListProposalVotesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listProposalVotes(input:))
    }
}

extension ListProposalVotesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListProposalVotesInput {
        return ListProposalVotesInput(
            maxResults: self.maxResults,
            networkId: self.networkId,
            nextToken: token,
            proposalId: self.proposalId
        )}
}