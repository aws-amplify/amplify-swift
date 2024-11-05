//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension MediaConnectClient {
    /// Paginate over `[ListBridgesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListBridgesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListBridgesOutput`
    public func listBridgesPaginated(input: ListBridgesInput) -> ClientRuntime.PaginatorSequence<ListBridgesInput, ListBridgesOutput> {
        return ClientRuntime.PaginatorSequence<ListBridgesInput, ListBridgesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listBridges(input:))
    }
}

extension ListBridgesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListBridgesInput {
        return ListBridgesInput(
            filterArn: self.filterArn,
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListBridgesInput, OperationStackOutput == ListBridgesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listBridgesPaginated`
    /// to access the nested member `[MediaConnectClientTypes.ListedBridge]`
    /// - Returns: `[MediaConnectClientTypes.ListedBridge]`
    public func bridges() async throws -> [MediaConnectClientTypes.ListedBridge] {
        return try await self.asyncCompactMap { item in item.bridges }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListEntitlementsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListEntitlementsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListEntitlementsOutput`
    public func listEntitlementsPaginated(input: ListEntitlementsInput) -> ClientRuntime.PaginatorSequence<ListEntitlementsInput, ListEntitlementsOutput> {
        return ClientRuntime.PaginatorSequence<ListEntitlementsInput, ListEntitlementsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listEntitlements(input:))
    }
}

extension ListEntitlementsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListEntitlementsInput {
        return ListEntitlementsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListEntitlementsInput, OperationStackOutput == ListEntitlementsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listEntitlementsPaginated`
    /// to access the nested member `[MediaConnectClientTypes.ListedEntitlement]`
    /// - Returns: `[MediaConnectClientTypes.ListedEntitlement]`
    public func entitlements() async throws -> [MediaConnectClientTypes.ListedEntitlement] {
        return try await self.asyncCompactMap { item in item.entitlements }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListFlowsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListFlowsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListFlowsOutput`
    public func listFlowsPaginated(input: ListFlowsInput) -> ClientRuntime.PaginatorSequence<ListFlowsInput, ListFlowsOutput> {
        return ClientRuntime.PaginatorSequence<ListFlowsInput, ListFlowsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listFlows(input:))
    }
}

extension ListFlowsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListFlowsInput {
        return ListFlowsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListFlowsInput, OperationStackOutput == ListFlowsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listFlowsPaginated`
    /// to access the nested member `[MediaConnectClientTypes.ListedFlow]`
    /// - Returns: `[MediaConnectClientTypes.ListedFlow]`
    public func flows() async throws -> [MediaConnectClientTypes.ListedFlow] {
        return try await self.asyncCompactMap { item in item.flows }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListGatewayInstancesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListGatewayInstancesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListGatewayInstancesOutput`
    public func listGatewayInstancesPaginated(input: ListGatewayInstancesInput) -> ClientRuntime.PaginatorSequence<ListGatewayInstancesInput, ListGatewayInstancesOutput> {
        return ClientRuntime.PaginatorSequence<ListGatewayInstancesInput, ListGatewayInstancesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listGatewayInstances(input:))
    }
}

extension ListGatewayInstancesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListGatewayInstancesInput {
        return ListGatewayInstancesInput(
            filterArn: self.filterArn,
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListGatewayInstancesInput, OperationStackOutput == ListGatewayInstancesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listGatewayInstancesPaginated`
    /// to access the nested member `[MediaConnectClientTypes.ListedGatewayInstance]`
    /// - Returns: `[MediaConnectClientTypes.ListedGatewayInstance]`
    public func instances() async throws -> [MediaConnectClientTypes.ListedGatewayInstance] {
        return try await self.asyncCompactMap { item in item.instances }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListGatewaysOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListGatewaysInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListGatewaysOutput`
    public func listGatewaysPaginated(input: ListGatewaysInput) -> ClientRuntime.PaginatorSequence<ListGatewaysInput, ListGatewaysOutput> {
        return ClientRuntime.PaginatorSequence<ListGatewaysInput, ListGatewaysOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listGateways(input:))
    }
}

extension ListGatewaysInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListGatewaysInput {
        return ListGatewaysInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListGatewaysInput, OperationStackOutput == ListGatewaysOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listGatewaysPaginated`
    /// to access the nested member `[MediaConnectClientTypes.ListedGateway]`
    /// - Returns: `[MediaConnectClientTypes.ListedGateway]`
    public func gateways() async throws -> [MediaConnectClientTypes.ListedGateway] {
        return try await self.asyncCompactMap { item in item.gateways }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListOfferingsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListOfferingsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListOfferingsOutput`
    public func listOfferingsPaginated(input: ListOfferingsInput) -> ClientRuntime.PaginatorSequence<ListOfferingsInput, ListOfferingsOutput> {
        return ClientRuntime.PaginatorSequence<ListOfferingsInput, ListOfferingsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listOfferings(input:))
    }
}

extension ListOfferingsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListOfferingsInput {
        return ListOfferingsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListOfferingsInput, OperationStackOutput == ListOfferingsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listOfferingsPaginated`
    /// to access the nested member `[MediaConnectClientTypes.Offering]`
    /// - Returns: `[MediaConnectClientTypes.Offering]`
    public func offerings() async throws -> [MediaConnectClientTypes.Offering] {
        return try await self.asyncCompactMap { item in item.offerings }
    }
}
extension MediaConnectClient {
    /// Paginate over `[ListReservationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListReservationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListReservationsOutput`
    public func listReservationsPaginated(input: ListReservationsInput) -> ClientRuntime.PaginatorSequence<ListReservationsInput, ListReservationsOutput> {
        return ClientRuntime.PaginatorSequence<ListReservationsInput, ListReservationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listReservations(input:))
    }
}

extension ListReservationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListReservationsInput {
        return ListReservationsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListReservationsInput, OperationStackOutput == ListReservationsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listReservationsPaginated`
    /// to access the nested member `[MediaConnectClientTypes.Reservation]`
    /// - Returns: `[MediaConnectClientTypes.Reservation]`
    public func reservations() async throws -> [MediaConnectClientTypes.Reservation] {
        return try await self.asyncCompactMap { item in item.reservations }
    }
}