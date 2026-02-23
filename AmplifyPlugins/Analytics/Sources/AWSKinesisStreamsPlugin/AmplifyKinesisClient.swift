//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
import AmplifyFoundation
import AmplifyFoundationBridge
import Foundation
import AWSKinesis
import AWSClientRuntime
import SmithyIdentity
@preconcurrency import struct os.OSAllocatedUnfairLock

public typealias KinesisClientConfigurationProvider = (inout AWSKinesis.KinesisClient.KinesisClientConfiguration) -> Void

/**
 * Kinesis supports up to 500 records per stream.
 * See [the docs](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html)
 */
private let maxRecordsPerStream = 500

/// A client for sending data to Amazon Kinesis Data Streams.
///
/// Provides automatic batching, retry logic, and local caching for high-throughput
/// data streaming to Kinesis with configurable flush strategies.
///
/// Example usage:
/// ```swift
/// let kinesis = try AmplifyKinesisClient(
///     region: "us-east-1",
///     credentialsProvider: credentialsProvider
/// )
///
/// // Record data
/// let result = try await kinesis.record(
///     data: "Hello Kinesis".data(using: .utf8)!,
///     streamName: "my-stream",
///     partitionKey: "partition-1"
/// )
///
/// // Flush cached records
/// let flushResult = try await kinesis.flush()
/// ```
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class AmplifyKinesisClient {
    private let kinesisClient: AWSKinesis.KinesisClient
    private let recordClient: RecordClient
    private let options: Options
    private let scheduler: AutoFlushScheduler
    private let logger = AmplifyLogging.logger(for: String(describing: AmplifyKinesisClient.self))
    private let isEnabled = OSAllocatedUnfairLock(initialState: false)

    /// Configuration options for AmplifyKinesisClient
    public struct Options {
        public static let defaultCacheMaxBytes: Int64 = 5 * 1024 * 1024 // 5MB
        public static let defaultMaxRetries: Int = 5

        public let cacheMaxBytes: Int64
        public let maxRetries: Int
        public let flushStrategy: FlushStrategy
        public let configureClient: KinesisClientConfigurationProvider?

        public init(
            cacheMaxBytes: Int64 = defaultCacheMaxBytes,
            maxRetries: Int = defaultMaxRetries,
            flushStrategy: FlushStrategy = .interval(),
            configureClient: KinesisClientConfigurationProvider? = nil
        ) {
            self.cacheMaxBytes = cacheMaxBytes
            self.maxRetries = maxRetries
            self.flushStrategy = flushStrategy
            self.configureClient = configureClient
        }
    }

    /// Initializes a new AmplifyKinesisClient instance
    /// - Parameters:
    ///   - region: AWS region
    ///   - credentialsProvider: Optional custom credentials provider. If nil, uses Amplify Auth credentials.
    ///   - options: Configuration options
    public init(
        region: String,
        credentialsProvider: (any AmplifyFoundation.AWSCredentialsProvider)? = nil,
        options: Options = Options()
    ) throws {
        self.options = options

        // Create Kinesis client configuration
        var clientConfig = try AWSKinesis.KinesisClient.KinesisClientConfiguration(region: region)

        // Set credentials provider - use provided resolver or default to Amplify Auth
        if let credentialsProvider = credentialsProvider {
            // Bridge the foundation credentials provider to SDK resolver
            clientConfig.awsCredentialIdentityResolver = credentialsProvider as? any AWSCredentialIdentityResolver
                ?? AWSAuthService().getCredentialIdentityResolver()
        } else {
            clientConfig.awsCredentialIdentityResolver = AWSAuthService().getCredentialIdentityResolver()
        }

        // Apply custom configuration if provided
        if let configureClient = options.configureClient {
            configureClient(&clientConfig)
        }

        self.kinesisClient = AWSKinesis.KinesisClient(config: clientConfig)

        // Create RecordClient with Kinesis-specific sender
        let sender = KinesisRecordSender(
            kinesisClient: kinesisClient,
            maxRetries: options.maxRetries
        )

        let storage = try SQLiteRecordStorage(
            identifier: region,
            maxRecords: maxRecordsPerStream,
            maxBytes: options.cacheMaxBytes
        )

        self.recordClient = RecordClient(
            sender: sender,
            storage: storage
        )

        // Create and setup flush scheduler
        let interval: Duration
        switch options.flushStrategy {
        case .interval(let value):
            interval = value
        }

        self.scheduler = AutoFlushScheduler(
            interval: interval,
            recordClient: recordClient
        )
    }

    /// Records data to a Kinesis stream
    /// - Parameters:
    ///   - data: The data to record
    ///   - partitionKey: The partition key for the record
    ///   - streamName: The name of the Kinesis stream
    /// - Returns: RecordData containing the result of the record operation
    /// - Throws: KinesisError if the record cannot be saved
    @discardableResult
    public func record(data: Data, partitionKey: String, streamName: String) async throws -> RecordData {
        guard isEnabled.withLock({ $0 }) else {
            logger.debug("Record collection is disabled, dropping record")
            return RecordData()
        }
        logger.verbose("Recording to stream: \(streamName)")
        
        return try await logOp(
            operation: {
                let input = RecordInput(
                    streamName: streamName,
                    partitionKey: partitionKey,
                    data: data
                )
                return try await wrapError {
                    try await recordClient.record(input)
                }
            },
            logSuccess: { _, timeMs in
                logger.debug("Record completed successfully in \(timeMs)ms")
            },
            logFailure: { error, timeMs in
                logger.warn("Record failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Flushes all cached records to Kinesis
    /// - Returns: FlushData containing the number of records flushed
    /// - Throws: KinesisError if flush fails
    @discardableResult
    public func flush() async throws -> FlushData {
        logger.info("Starting flush")
        return try await logOp(
            operation: {
                try await wrapError {
                    try await recordClient.flush()
                }
            },
            logSuccess: { data, timeMs in
                logger.info("Flush completed successfully in \(timeMs)ms - \(data.recordsFlushed) records flushed")
            },
            logFailure: { error, timeMs in
                logger.warn("Flush failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Disables record collection and automatic flushing. Records submitted while
    /// disabled are silently dropped. Already-cached records remain in storage.
    public func disable() async {
        isEnabled.withLock { $0 = false }
        await scheduler.disable()
    }

    /// Enables record collection and automatic flushing of cached records.
    public func enable() async {
        isEnabled.withLock { $0 = true }
        await scheduler.start()
    }

    /// Clears all cached records
    /// - Returns: ClearCacheData containing the number of records cleared
    /// - Throws: KinesisError if cache cannot be cleared
    @discardableResult
    public func clearCache() async throws -> ClearCacheData {
        logger.info("Clearing cache")
        return try await logOp(
            operation: {
                try await wrapError {
                    try await recordClient.clearCache()
                }
            },
            logSuccess: { data, timeMs in
                logger.info("Clear cache completed successfully in \(timeMs)ms - \(data.recordsCleared) records cleared")
            },
            logFailure: { error, timeMs in
                logger.warn("Clear cache failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Returns the underlying Kinesis client for advanced use cases
    public func getKinesisClient() -> AWSKinesis.KinesisClient {
        return kinesisClient
    }

    /// Wraps an async operation, converting internal errors to KinesisError via ``KinesisError/from(_:)``.
    private func wrapError<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as KinesisError {
            throw error
        } catch {
            throw KinesisError.from(error)
        }
    }

    /// Measures and logs the execution time of an async operation
    private func logOp<T>(
        operation: () async throws -> T,
        logSuccess: (T, Int) -> Void,
        logFailure: (Error, Int) -> Void
    ) async throws -> T {
        var result: T!
        var error: Error?
        
        let duration = await ContinuousClock().measure {
            do {
                result = try await operation()
            } catch let e {
                error = e
            }
        }
        
        let timeMs = Int(duration.components.seconds * 1000 + Int64(duration.components.attoseconds) / 1_000_000_000_000_000)
        
        if let error = error {
            logFailure(error, timeMs)
            throw error
        } else {
            logSuccess(result, timeMs)
            return result
        }
    }

    deinit {
        Task { [scheduler] in
            await scheduler.disable()
        }
    }
}
