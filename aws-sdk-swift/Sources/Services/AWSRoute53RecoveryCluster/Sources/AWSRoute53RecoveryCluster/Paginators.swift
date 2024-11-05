//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension Route53RecoveryClusterClient {
    /// Paginate over `[ListRoutingControlsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListRoutingControlsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListRoutingControlsOutput`
    public func listRoutingControlsPaginated(input: ListRoutingControlsInput) -> ClientRuntime.PaginatorSequence<ListRoutingControlsInput, ListRoutingControlsOutput> {
        return ClientRuntime.PaginatorSequence<ListRoutingControlsInput, ListRoutingControlsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listRoutingControls(input:))
    }
}

extension ListRoutingControlsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListRoutingControlsInput {
        return ListRoutingControlsInput(
            controlPanelArn: self.controlPanelArn,
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListRoutingControlsInput, OperationStackOutput == ListRoutingControlsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listRoutingControlsPaginated`
    /// to access the nested member `[Route53RecoveryClusterClientTypes.RoutingControl]`
    /// - Returns: `[Route53RecoveryClusterClientTypes.RoutingControl]`
    public func routingControls() async throws -> [Route53RecoveryClusterClientTypes.RoutingControl] {
        return try await self.asyncCompactMap { item in item.routingControls }
    }
}