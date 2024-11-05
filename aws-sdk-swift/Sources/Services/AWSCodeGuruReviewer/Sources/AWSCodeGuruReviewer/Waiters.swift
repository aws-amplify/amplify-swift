//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Code generated by smithy-swift-codegen. DO NOT EDIT!

import class SmithyWaitersAPI.Waiter
import enum SmithyWaitersAPI.JMESUtils
import struct SmithyWaitersAPI.WaiterConfiguration
import struct SmithyWaitersAPI.WaiterOptions
import struct SmithyWaitersAPI.WaiterOutcome

extension CodeGuruReviewerClient {

    static func codeReviewCompletedWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeCodeReviewInput, DescribeCodeReviewOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeCodeReviewInput, DescribeCodeReviewOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeCodeReviewInput, result: Swift.Result<DescribeCodeReviewOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "CodeReview.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Completed"
                guard case .success(let output) = result else { return false }
                let codeReview = output.codeReview
                let state = codeReview?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Completed")
            }),
            .init(state: .failure, matcher: { (input: DescribeCodeReviewInput, result: Swift.Result<DescribeCodeReviewOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "CodeReview.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Failed"
                guard case .success(let output) = result else { return false }
                let codeReview = output.codeReview
                let state = codeReview?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Failed")
            }),
            .init(state: .retry, matcher: { (input: DescribeCodeReviewInput, result: Swift.Result<DescribeCodeReviewOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "CodeReview.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Pending"
                guard case .success(let output) = result else { return false }
                let codeReview = output.codeReview
                let state = codeReview?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Pending")
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeCodeReviewInput, DescribeCodeReviewOutput>(acceptors: acceptors, minDelay: 10.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the CodeReviewCompleted event on the describeCodeReview operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeCodeReviewInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilCodeReviewCompleted(options: SmithyWaitersAPI.WaiterOptions, input: DescribeCodeReviewInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeCodeReviewOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.codeReviewCompletedWaiterConfig(), operation: self.describeCodeReview(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }

    static func repositoryAssociationSucceededWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeRepositoryAssociationInput, DescribeRepositoryAssociationOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeRepositoryAssociationInput, DescribeRepositoryAssociationOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeRepositoryAssociationInput, result: Swift.Result<DescribeRepositoryAssociationOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "RepositoryAssociation.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Associated"
                guard case .success(let output) = result else { return false }
                let repositoryAssociation = output.repositoryAssociation
                let state = repositoryAssociation?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Associated")
            }),
            .init(state: .failure, matcher: { (input: DescribeRepositoryAssociationInput, result: Swift.Result<DescribeRepositoryAssociationOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "RepositoryAssociation.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Failed"
                guard case .success(let output) = result else { return false }
                let repositoryAssociation = output.repositoryAssociation
                let state = repositoryAssociation?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Failed")
            }),
            .init(state: .retry, matcher: { (input: DescribeRepositoryAssociationInput, result: Swift.Result<DescribeRepositoryAssociationOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "RepositoryAssociation.State"
                // JMESPath comparator: "stringEquals"
                // JMESPath expected value: "Associating"
                guard case .success(let output) = result else { return false }
                let repositoryAssociation = output.repositoryAssociation
                let state = repositoryAssociation?.state
                return SmithyWaitersAPI.JMESUtils.compare(state, ==, "Associating")
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeRepositoryAssociationInput, DescribeRepositoryAssociationOutput>(acceptors: acceptors, minDelay: 10.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the RepositoryAssociationSucceeded event on the describeRepositoryAssociation operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeRepositoryAssociationInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilRepositoryAssociationSucceeded(options: SmithyWaitersAPI.WaiterOptions, input: DescribeRepositoryAssociationInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeRepositoryAssociationOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.repositoryAssociationSucceededWaiterConfig(), operation: self.describeRepositoryAssociation(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }
}