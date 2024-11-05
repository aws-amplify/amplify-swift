//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import protocol ClientRuntime.PaginateToken
import struct ClientRuntime.PaginatorSequence

extension AppConfigClient {
    /// Paginate over `[ListApplicationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListApplicationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListApplicationsOutput`
    public func listApplicationsPaginated(input: ListApplicationsInput) -> ClientRuntime.PaginatorSequence<ListApplicationsInput, ListApplicationsOutput> {
        return ClientRuntime.PaginatorSequence<ListApplicationsInput, ListApplicationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listApplications(input:))
    }
}

extension ListApplicationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListApplicationsInput {
        return ListApplicationsInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListApplicationsInput, OperationStackOutput == ListApplicationsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listApplicationsPaginated`
    /// to access the nested member `[AppConfigClientTypes.Application]`
    /// - Returns: `[AppConfigClientTypes.Application]`
    public func items() async throws -> [AppConfigClientTypes.Application] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListConfigurationProfilesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListConfigurationProfilesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListConfigurationProfilesOutput`
    public func listConfigurationProfilesPaginated(input: ListConfigurationProfilesInput) -> ClientRuntime.PaginatorSequence<ListConfigurationProfilesInput, ListConfigurationProfilesOutput> {
        return ClientRuntime.PaginatorSequence<ListConfigurationProfilesInput, ListConfigurationProfilesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listConfigurationProfiles(input:))
    }
}

extension ListConfigurationProfilesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListConfigurationProfilesInput {
        return ListConfigurationProfilesInput(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token,
            type: self.type
        )}
}

extension PaginatorSequence where OperationStackInput == ListConfigurationProfilesInput, OperationStackOutput == ListConfigurationProfilesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listConfigurationProfilesPaginated`
    /// to access the nested member `[AppConfigClientTypes.ConfigurationProfileSummary]`
    /// - Returns: `[AppConfigClientTypes.ConfigurationProfileSummary]`
    public func items() async throws -> [AppConfigClientTypes.ConfigurationProfileSummary] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListDeploymentsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListDeploymentsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListDeploymentsOutput`
    public func listDeploymentsPaginated(input: ListDeploymentsInput) -> ClientRuntime.PaginatorSequence<ListDeploymentsInput, ListDeploymentsOutput> {
        return ClientRuntime.PaginatorSequence<ListDeploymentsInput, ListDeploymentsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listDeployments(input:))
    }
}

extension ListDeploymentsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListDeploymentsInput {
        return ListDeploymentsInput(
            applicationId: self.applicationId,
            environmentId: self.environmentId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListDeploymentsInput, OperationStackOutput == ListDeploymentsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listDeploymentsPaginated`
    /// to access the nested member `[AppConfigClientTypes.DeploymentSummary]`
    /// - Returns: `[AppConfigClientTypes.DeploymentSummary]`
    public func items() async throws -> [AppConfigClientTypes.DeploymentSummary] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListDeploymentStrategiesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListDeploymentStrategiesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListDeploymentStrategiesOutput`
    public func listDeploymentStrategiesPaginated(input: ListDeploymentStrategiesInput) -> ClientRuntime.PaginatorSequence<ListDeploymentStrategiesInput, ListDeploymentStrategiesOutput> {
        return ClientRuntime.PaginatorSequence<ListDeploymentStrategiesInput, ListDeploymentStrategiesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listDeploymentStrategies(input:))
    }
}

extension ListDeploymentStrategiesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListDeploymentStrategiesInput {
        return ListDeploymentStrategiesInput(
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListDeploymentStrategiesInput, OperationStackOutput == ListDeploymentStrategiesOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listDeploymentStrategiesPaginated`
    /// to access the nested member `[AppConfigClientTypes.DeploymentStrategy]`
    /// - Returns: `[AppConfigClientTypes.DeploymentStrategy]`
    public func items() async throws -> [AppConfigClientTypes.DeploymentStrategy] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListEnvironmentsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListEnvironmentsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListEnvironmentsOutput`
    public func listEnvironmentsPaginated(input: ListEnvironmentsInput) -> ClientRuntime.PaginatorSequence<ListEnvironmentsInput, ListEnvironmentsOutput> {
        return ClientRuntime.PaginatorSequence<ListEnvironmentsInput, ListEnvironmentsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listEnvironments(input:))
    }
}

extension ListEnvironmentsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListEnvironmentsInput {
        return ListEnvironmentsInput(
            applicationId: self.applicationId,
            maxResults: self.maxResults,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListEnvironmentsInput, OperationStackOutput == ListEnvironmentsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listEnvironmentsPaginated`
    /// to access the nested member `[AppConfigClientTypes.Environment]`
    /// - Returns: `[AppConfigClientTypes.Environment]`
    public func items() async throws -> [AppConfigClientTypes.Environment] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListExtensionAssociationsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListExtensionAssociationsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListExtensionAssociationsOutput`
    public func listExtensionAssociationsPaginated(input: ListExtensionAssociationsInput) -> ClientRuntime.PaginatorSequence<ListExtensionAssociationsInput, ListExtensionAssociationsOutput> {
        return ClientRuntime.PaginatorSequence<ListExtensionAssociationsInput, ListExtensionAssociationsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listExtensionAssociations(input:))
    }
}

extension ListExtensionAssociationsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListExtensionAssociationsInput {
        return ListExtensionAssociationsInput(
            extensionIdentifier: self.extensionIdentifier,
            extensionVersionNumber: self.extensionVersionNumber,
            maxResults: self.maxResults,
            nextToken: token,
            resourceIdentifier: self.resourceIdentifier
        )}
}

extension PaginatorSequence where OperationStackInput == ListExtensionAssociationsInput, OperationStackOutput == ListExtensionAssociationsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listExtensionAssociationsPaginated`
    /// to access the nested member `[AppConfigClientTypes.ExtensionAssociationSummary]`
    /// - Returns: `[AppConfigClientTypes.ExtensionAssociationSummary]`
    public func items() async throws -> [AppConfigClientTypes.ExtensionAssociationSummary] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListExtensionsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListExtensionsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListExtensionsOutput`
    public func listExtensionsPaginated(input: ListExtensionsInput) -> ClientRuntime.PaginatorSequence<ListExtensionsInput, ListExtensionsOutput> {
        return ClientRuntime.PaginatorSequence<ListExtensionsInput, ListExtensionsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listExtensions(input:))
    }
}

extension ListExtensionsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListExtensionsInput {
        return ListExtensionsInput(
            maxResults: self.maxResults,
            name: self.name,
            nextToken: token
        )}
}

extension PaginatorSequence where OperationStackInput == ListExtensionsInput, OperationStackOutput == ListExtensionsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listExtensionsPaginated`
    /// to access the nested member `[AppConfigClientTypes.ExtensionSummary]`
    /// - Returns: `[AppConfigClientTypes.ExtensionSummary]`
    public func items() async throws -> [AppConfigClientTypes.ExtensionSummary] {
        return try await self.asyncCompactMap { item in item.items }
    }
}
extension AppConfigClient {
    /// Paginate over `[ListHostedConfigurationVersionsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListHostedConfigurationVersionsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListHostedConfigurationVersionsOutput`
    public func listHostedConfigurationVersionsPaginated(input: ListHostedConfigurationVersionsInput) -> ClientRuntime.PaginatorSequence<ListHostedConfigurationVersionsInput, ListHostedConfigurationVersionsOutput> {
        return ClientRuntime.PaginatorSequence<ListHostedConfigurationVersionsInput, ListHostedConfigurationVersionsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listHostedConfigurationVersions(input:))
    }
}

extension ListHostedConfigurationVersionsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListHostedConfigurationVersionsInput {
        return ListHostedConfigurationVersionsInput(
            applicationId: self.applicationId,
            configurationProfileId: self.configurationProfileId,
            maxResults: self.maxResults,
            nextToken: token,
            versionLabel: self.versionLabel
        )}
}

extension PaginatorSequence where OperationStackInput == ListHostedConfigurationVersionsInput, OperationStackOutput == ListHostedConfigurationVersionsOutput {
    /// This paginator transforms the `AsyncSequence` returned by `listHostedConfigurationVersionsPaginated`
    /// to access the nested member `[AppConfigClientTypes.HostedConfigurationVersionSummary]`
    /// - Returns: `[AppConfigClientTypes.HostedConfigurationVersionSummary]`
    public func items() async throws -> [AppConfigClientTypes.HostedConfigurationVersionSummary] {
        return try await self.asyncCompactMap { item in item.items }
    }
}