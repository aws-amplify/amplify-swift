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

extension MachineLearningClient {

    static func batchPredictionAvailableWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeBatchPredictionsInput, DescribeBatchPredictionsOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeBatchPredictionsInput, DescribeBatchPredictionsOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeBatchPredictionsInput, result: Swift.Result<DescribeBatchPredictionsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "allStringEquals"
                // JMESPath expected value: "COMPLETED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return (projection?.count ?? 0) > 1 && (projection?.allSatisfy { SmithyWaitersAPI.JMESUtils.compare($0, ==, "COMPLETED") } ?? false)
            }),
            .init(state: .failure, matcher: { (input: DescribeBatchPredictionsInput, result: Swift.Result<DescribeBatchPredictionsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "anyStringEquals"
                // JMESPath expected value: "FAILED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return projection?.contains(where: { SmithyWaitersAPI.JMESUtils.compare($0, ==, "FAILED") }) ?? false
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeBatchPredictionsInput, DescribeBatchPredictionsOutput>(acceptors: acceptors, minDelay: 30.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the BatchPredictionAvailable event on the describeBatchPredictions operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeBatchPredictionsInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilBatchPredictionAvailable(options: SmithyWaitersAPI.WaiterOptions, input: DescribeBatchPredictionsInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeBatchPredictionsOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.batchPredictionAvailableWaiterConfig(), operation: self.describeBatchPredictions(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }

    static func dataSourceAvailableWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeDataSourcesInput, DescribeDataSourcesOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeDataSourcesInput, DescribeDataSourcesOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeDataSourcesInput, result: Swift.Result<DescribeDataSourcesOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "allStringEquals"
                // JMESPath expected value: "COMPLETED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return (projection?.count ?? 0) > 1 && (projection?.allSatisfy { SmithyWaitersAPI.JMESUtils.compare($0, ==, "COMPLETED") } ?? false)
            }),
            .init(state: .failure, matcher: { (input: DescribeDataSourcesInput, result: Swift.Result<DescribeDataSourcesOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "anyStringEquals"
                // JMESPath expected value: "FAILED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return projection?.contains(where: { SmithyWaitersAPI.JMESUtils.compare($0, ==, "FAILED") }) ?? false
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeDataSourcesInput, DescribeDataSourcesOutput>(acceptors: acceptors, minDelay: 30.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the DataSourceAvailable event on the describeDataSources operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeDataSourcesInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilDataSourceAvailable(options: SmithyWaitersAPI.WaiterOptions, input: DescribeDataSourcesInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeDataSourcesOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.dataSourceAvailableWaiterConfig(), operation: self.describeDataSources(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }

    static func evaluationAvailableWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeEvaluationsInput, DescribeEvaluationsOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeEvaluationsInput, DescribeEvaluationsOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeEvaluationsInput, result: Swift.Result<DescribeEvaluationsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "allStringEquals"
                // JMESPath expected value: "COMPLETED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return (projection?.count ?? 0) > 1 && (projection?.allSatisfy { SmithyWaitersAPI.JMESUtils.compare($0, ==, "COMPLETED") } ?? false)
            }),
            .init(state: .failure, matcher: { (input: DescribeEvaluationsInput, result: Swift.Result<DescribeEvaluationsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "anyStringEquals"
                // JMESPath expected value: "FAILED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return projection?.contains(where: { SmithyWaitersAPI.JMESUtils.compare($0, ==, "FAILED") }) ?? false
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeEvaluationsInput, DescribeEvaluationsOutput>(acceptors: acceptors, minDelay: 30.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the EvaluationAvailable event on the describeEvaluations operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeEvaluationsInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilEvaluationAvailable(options: SmithyWaitersAPI.WaiterOptions, input: DescribeEvaluationsInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeEvaluationsOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.evaluationAvailableWaiterConfig(), operation: self.describeEvaluations(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }

    static func mlModelAvailableWaiterConfig() throws -> SmithyWaitersAPI.WaiterConfiguration<DescribeMLModelsInput, DescribeMLModelsOutput> {
        let acceptors: [SmithyWaitersAPI.WaiterConfiguration<DescribeMLModelsInput, DescribeMLModelsOutput>.Acceptor] = [
            .init(state: .success, matcher: { (input: DescribeMLModelsInput, result: Swift.Result<DescribeMLModelsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "allStringEquals"
                // JMESPath expected value: "COMPLETED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return (projection?.count ?? 0) > 1 && (projection?.allSatisfy { SmithyWaitersAPI.JMESUtils.compare($0, ==, "COMPLETED") } ?? false)
            }),
            .init(state: .failure, matcher: { (input: DescribeMLModelsInput, result: Swift.Result<DescribeMLModelsOutput, Swift.Error>) -> Bool in
                // JMESPath expression: "Results[].Status"
                // JMESPath comparator: "anyStringEquals"
                // JMESPath expected value: "FAILED"
                guard case .success(let output) = result else { return false }
                let results = output.results
                let projection: [MachineLearningClientTypes.EntityStatus]? = results?.compactMap { original in
                    let status = original.status
                    return status
                }
                return projection?.contains(where: { SmithyWaitersAPI.JMESUtils.compare($0, ==, "FAILED") }) ?? false
            }),
        ]
        return try SmithyWaitersAPI.WaiterConfiguration<DescribeMLModelsInput, DescribeMLModelsOutput>(acceptors: acceptors, minDelay: 30.0, maxDelay: 120.0)
    }

    /// Initiates waiting for the MLModelAvailable event on the describeMLModels operation.
    /// The operation will be tried and (if necessary) retried until the wait succeeds, fails, or times out.
    /// Returns a `WaiterOutcome` asynchronously on waiter success, throws an error asynchronously on
    /// waiter failure or timeout.
    /// - Parameters:
    ///   - options: `WaiterOptions` to be used to configure this wait.
    ///   - input: The `DescribeMLModelsInput` object to be used as a parameter when performing the operation.
    /// - Returns: A `WaiterOutcome` with the result of the final, successful performance of the operation.
    /// - Throws: `WaiterFailureError` if the waiter fails due to matching an `Acceptor` with state `failure`
    /// or there is an error not handled by any `Acceptor.`
    /// `WaiterTimeoutError` if the waiter times out.
    public func waitUntilMLModelAvailable(options: SmithyWaitersAPI.WaiterOptions, input: DescribeMLModelsInput) async throws -> SmithyWaitersAPI.WaiterOutcome<DescribeMLModelsOutput> {
        let waiter = SmithyWaitersAPI.Waiter(config: try Self.mlModelAvailableWaiterConfig(), operation: self.describeMLModels(input:))
        return try await waiter.waitUntil(options: options, input: input)
    }
}