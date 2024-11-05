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

extension SignerClient {
    /// Paginate over `[ListSigningJobsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSigningJobsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSigningJobsOutput`
    public func listSigningJobsPaginated(input: ListSigningJobsInput) -> ClientRuntime.PaginatorSequence<ListSigningJobsInput, ListSigningJobsOutput> {
        return ClientRuntime.PaginatorSequence<ListSigningJobsInput, ListSigningJobsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSigningJobs(input:))
    }
}

extension ListSigningJobsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSigningJobsInput {
        return ListSigningJobsInput(
            isRevoked: self.isRevoked,
            jobInvoker: self.jobInvoker,
            maxResults: self.maxResults,
            nextToken: token,
            platformId: self.platformId,
            requestedBy: self.requestedBy,
            signatureExpiresAfter: self.signatureExpiresAfter,
            signatureExpiresBefore: self.signatureExpiresBefore,
            status: self.status
        )}
}
extension SignerClient {
    /// Paginate over `[ListSigningPlatformsOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSigningPlatformsInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSigningPlatformsOutput`
    public func listSigningPlatformsPaginated(input: ListSigningPlatformsInput) -> ClientRuntime.PaginatorSequence<ListSigningPlatformsInput, ListSigningPlatformsOutput> {
        return ClientRuntime.PaginatorSequence<ListSigningPlatformsInput, ListSigningPlatformsOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSigningPlatforms(input:))
    }
}

extension ListSigningPlatformsInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSigningPlatformsInput {
        return ListSigningPlatformsInput(
            category: self.category,
            maxResults: self.maxResults,
            nextToken: token,
            partner: self.partner,
            target: self.target
        )}
}
extension SignerClient {
    /// Paginate over `[ListSigningProfilesOutput]` results.
    ///
    /// When this operation is called, an `AsyncSequence` is created. AsyncSequences are lazy so no service
    /// calls are made until the sequence is iterated over. This also means there is no guarantee that the request is valid
    /// until then. If there are errors in your request, you will see the failures only after you start iterating.
    /// - Parameters:
    ///     - input: A `[ListSigningProfilesInput]` to start pagination
    /// - Returns: An `AsyncSequence` that can iterate over `ListSigningProfilesOutput`
    public func listSigningProfilesPaginated(input: ListSigningProfilesInput) -> ClientRuntime.PaginatorSequence<ListSigningProfilesInput, ListSigningProfilesOutput> {
        return ClientRuntime.PaginatorSequence<ListSigningProfilesInput, ListSigningProfilesOutput>(input: input, inputKey: \.nextToken, outputKey: \.nextToken, paginationFunction: self.listSigningProfiles(input:))
    }
}

extension ListSigningProfilesInput: ClientRuntime.PaginateToken {
    public func usingPaginationToken(_ token: Swift.String) -> ListSigningProfilesInput {
        return ListSigningProfilesInput(
            includeCanceled: self.includeCanceled,
            maxResults: self.maxResults,
            nextToken: token,
            platformId: self.platformId,
            statuses: self.statuses
        )}
}