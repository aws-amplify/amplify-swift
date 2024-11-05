//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension SupportAppClient {
    /// Paginate over `[ListSlackChannelConfigurationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSlackChannelConfigurationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSlackChannelConfigurationsOutput`
    public func listSlackChannelConfigurationsPaginated(input: ListSlackChannelConfigurationsInput) -> ClientRuntime.PaginatorSequence<ListSlackChannelConfigurationsInput, ListSlackChannelConfigurationsOutput> {
        return ClientRuntime.PaginatorSequence<ListSlackChannelConfigurationsInput, ListSlackChannelConfigurationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSlackChannelConfigurations(input:))
    }
}

extension ListSlackChannelConfigurationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSlackChannelConfigurationsInput {
        return ListSlackChannelConfigurationsInput(
            nextToken: token
        )}
}
extension SupportAppClient {
    /// Paginate over `[ListSlackWorkspaceConfigurationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSlackWorkspaceConfigurationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSlackWorkspaceConfigurationsOutput`
    public func listSlackWorkspaceConfigurationsPaginated(input: ListSlackWorkspaceConfigurationsInput) -> ClientRuntime.PaginatorSequence<ListSlackWorkspaceConfigurationsInput, ListSlackWorkspaceConfigurationsOutput> {
        return ClientRuntime.PaginatorSequence<ListSlackWorkspaceConfigurationsInput, ListSlackWorkspaceConfigurationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSlackWorkspaceConfigurations(input:))
    }
}

extension ListSlackWorkspaceConfigurationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSlackWorkspaceConfigurationsInput {
        return ListSlackWorkspaceConfigurationsInput(
            nextToken: token
        )}
}