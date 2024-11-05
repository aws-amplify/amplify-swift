//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import Foundation
import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension ApplicationSignalsClient {
    /// Paginate over `[ListServiceDependenciesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListServiceDependenciesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListServiceDependenciesOutput`
    public func listServiceDependenciesPaginated(input: ListServiceDependenciesInput) -> ClientRuntime.PaginatorSequence<ListServiceDependenciesInput, ListServiceDependenciesOutput> {
        return ClientRuntime.PaginatorSequence<ListServiceDependenciesInput, ListServiceDependenciesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listServiceDependencies(input:))
    }
}

extension ListServiceDependenciesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListServiceDependenciesInput {
        return ListServiceDependenciesInput(
            endTime: self.endTime,
            keyAttributes: self.keyAttributes,
            maxResults: self.maxResults,
            nextToken: token,
            startTime: self.startTime
        )}
}

extension PaginatorSequence where OperationStackInput == ListServiceDependenciesInput, OperationStackOutput == ListServiceDependenciesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listServiceDependenciesPaginated`
    /// to access the nested member `[ApplicationSignalsClientTypes.ServiceDependency]`
    /// - Returns: `[ApplicationSignalsClientTypes.ServiceDependency]`
    public func serviceDependencies() async throws -> [ApplicationSignalsClientTypes.ServiceDependency] {
        return try await self.asyncCompactMap { item in item.serviceDependencies }
    }
}
extension ApplicationSignalsClient {
    /// Paginate over `[ListServiceDependentsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListServiceDependentsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListServiceDependentsOutput`
    public func listServiceDependentsPaginated(input: ListServiceDependentsInput) -> ClientRuntime.PaginatorSequence<ListServiceDependentsInput, ListServiceDependentsOutput> {
        return ClientRuntime.PaginatorSequence<ListServiceDependentsInput, ListServiceDependentsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listServiceDependents(input:))
    }
}

extension ListServiceDependentsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListServiceDependentsInput {
        return ListServiceDependentsInput(
            endTime: self.endTime,
            keyAttributes: self.keyAttributes,
            maxResults: self.maxResults,
            nextToken: token,
            startTime: self.startTime
        )}
}

extension PaginatorSequence where OperationStackInput == ListServiceDependentsInput, OperationStackOutput == ListServiceDependentsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listServiceDependentsPaginated`
    /// to access the nested member `[ApplicationSignalsClientTypes.ServiceDependent]`
    /// - Returns: `[ApplicationSignalsClientTypes.ServiceDependent]`
    public func serviceDependents() async throws -> [ApplicationSignalsClientTypes.ServiceDependent] {
        return try await self.asyncCompactMap { item in item.serviceDependents }
    }
}
extension ApplicationSignalsClient {
    /// Paginate over `[ListServiceOperationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListServiceOperationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListServiceOperationsOutput`
    public func listServiceOperationsPaginated(input: ListServiceOperationsInput) -> ClientRuntime.PaginatorSequence<ListServiceOperationsInput, ListServiceOperationsOutput> {
        return ClientRuntime.PaginatorSequence<ListServiceOperationsInput, ListServiceOperationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listServiceOperations(input:))
    }
}

extension ListServiceOperationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListServiceOperationsInput {
        return ListServiceOperationsInput(
            endTime: self.endTime,
            keyAttributes: self.keyAttributes,
            maxResults: self.maxResults,
            nextToken: token,
            startTime: self.startTime
        )}
}

extension PaginatorSequence where OperationStackInput == ListServiceOperationsInput, OperationStackOutput == ListServiceOperationsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listServiceOperationsPaginated`
    /// to access the nested member `[ApplicationSignalsClientTypes.ServiceOperation]`
    /// - Returns: `[ApplicationSignalsClientTypes.ServiceOperation]`
    public func serviceOperations() async throws -> [ApplicationSignalsClientTypes.ServiceOperation] {
        return try await self.asyncCompactMap { item in item.serviceOperations }
    }
}
extension ApplicationSignalsClient {
    /// Paginate over `[ListServicesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListServicesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListServicesOutput`
    public func listServicesPaginated(input: ListServicesInput) -> ClientRuntime.PaginatorSequence<ListServicesInput, ListServicesOutput> {
        return ClientRuntime.PaginatorSequence<ListServicesInput, ListServicesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listServices(input:))
    }
}

extension ListServicesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListServicesInput {
        return ListServicesInput(
            endTime: self.endTime,
            maxResults: self.maxResults,
            nextToken: token,
            startTime: self.startTime
        )}
}

extension PaginatorSequence where OperationStackInput == ListServicesInput, OperationStackOutput == ListServicesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listServicesPaginated`
    /// to access the nested member `[ApplicationSignalsClientTypes.ServiceSummary]`
    /// - Returns: `[ApplicationSignalsClientTypes.ServiceSummary]`
    public func serviceSummaries() async throws -> [ApplicationSignalsClientTypes.ServiceSummary] {
        return try await self.asyncCompactMap { item in item.serviceSummaries }
    }
}