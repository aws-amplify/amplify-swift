//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
@_exported import AmplifyRecordCache
import AWSClientRuntime
import AWSKinesis
import Foundation
import SmithyIdentity

public typealias AmplifyKinesisClientConfigurationProvider = (
    inout AWSKinesis.KinesisClient.KinesisClientConfiguration
) -> Void

/// Kinesis supports up to 500 records per PutRecords request.
/// See [the docs](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html)
private let maxRecordsPerStream = 500

/// Maximum size of a single record (partition key + data blob) in bytes (10 MiB).
/// See [PutRecordsRequestEntry](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsRequestEntry.html)
private let maxRecordSizeBytes: Int64 = 10 * 1_024 * 1_024

/// Maximum total payload size per PutRecords request in bytes (10 MiB).
/// See [PutRecords](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html)
private let maxBytesPerStream: Int64 = 10 * 1_024 * 1_024

/// Maximum length of a partition key in Unicode scalars.
/// See [PutRecordsRequestEntry](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecordsRequestEntry.html)
private let maxPartitionKeyLength = 256

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
///
/// Converting AWS SDK v2 credentials provider to v3:
/// ```swift
/// // Create credentials provider from Amplify Auth
/// let credentialsProvider = SDKToFoundationCredentialsAdapter(
///     resolver: AWSAuthService().getCredentialIdentityResolver()
/// )
///
/// let kinesis = try AmplifyKinesisClient(
///     region: "us-east-1",
///     credentialsProvider: credentialsProvider
/// )
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public class AmplifyKinesisClient {
    private let kinesisClient: AWSKinesis.KinesisClient
    private let recordClient: AmplifyRecordCache.RecordClient
    private let options: Options
    private let scheduler: AmplifyRecordCache.AutoFlushScheduler?
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AmplifyKinesisClient.self)
    private let isEnabledLock = NSLock()
    private var _isEnabled = true

    private var isEnabledLocked: Bool {
        isEnabledLock.lock()
        defer { isEnabledLock.unlock() }
        return _isEnabled
    }

    /// Configuration options for AmplifyKinesisClient
    public struct Options {
        public let cacheMaxBytes: Int64
        public let maxRetries: Int
        public let flushStrategy: FlushStrategy

        /// Optional closure for advanced customization of the underlying `KinesisClientConfiguration`.
        ///
        /// This closure is applied before the credentials resolver is set. The `credentialsProvider`
        /// passed to ``AmplifyKinesisClient/init(region:credentialsProvider:options:)`` will always
        /// take precedence over any `awsCredentialIdentityResolver` set in this closure.
        public let configureClient: AmplifyKinesisClientConfigurationProvider?

        public init(
            cacheMaxBytes: Int64 = 5 * 1_024 * 1_024, // 5MB
            maxRetries: Int = 5,
            flushStrategy: FlushStrategy = .interval(),
            configureClient: AmplifyKinesisClientConfigurationProvider? = nil
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
    ///   - credentialsProvider: Foundation credential provider for AWS authentication
    ///   - options: Configuration options
    public init(
        region: String,
        credentialsProvider: any AmplifyFoundation.AWSCredentialsProvider,
        options: Options = Options()
    ) throws {
        self.options = options

        // Create Kinesis client configuration
        var clientConfig = try AWSKinesis.KinesisClient.KinesisClientConfiguration(region: region)

        if let configureClient = options.configureClient {
            configureClient(&clientConfig)
        }
        clientConfig.awsCredentialIdentityResolver = FoundationToSDKCredentialsAdapter(
            provider: credentialsProvider
        )

        // Wrap the default HTTP engine to append kinesis user agent metadata
        clientConfig.httpClientEngine = UserAgentClientEngine(
            target: clientConfig.httpClientEngine,
            additionalMetadata: ["md/amplify-kinesis"]
        )

        self.kinesisClient = AWSKinesis.KinesisClient(config: clientConfig)

        // Create RecordClient with Kinesis-specific sender
        let sender = KinesisRecordSender(
            kinesisClient: kinesisClient,
            maxRetries: options.maxRetries
        )

        let storage = try AmplifyRecordCache.SQLiteRecordStorage(
            dbPrefix: "kinesis_records",
            identifier: region,
            maxRecords: maxRecordsPerStream,
            cacheMaxBytes: options.cacheMaxBytes,
            maxRecordSizeBytes: maxRecordSizeBytes,
            maxBytesPerStream: maxBytesPerStream,
            maxPartitionKeyLength: maxPartitionKeyLength
        )

        self.recordClient = AmplifyRecordCache.RecordClient(
            sender: sender,
            storage: storage,
            maxRetries: options.maxRetries
        )

        // Create and setup flush scheduler
        switch options.flushStrategy {
        case .interval(let interval):
            let scheduler = AmplifyRecordCache.AutoFlushScheduler(
                interval: interval,
                recordClient: recordClient
            )
            self.scheduler = scheduler
            Task { await scheduler.start() }
        case .none:
            self.scheduler = nil
        }
    }

    /// Records data to a Kinesis stream
    /// - Parameters:
    ///   - data: The data to record
    ///   - partitionKey: The partition key for the record
    ///   - streamName: The name of the Kinesis stream
    /// - Returns: RecordData containing the result of the record operation
    /// - Throws: KinesisError if the record cannot be saved
    @discardableResult
    public func record(data: Data, partitionKey: String, streamName: String) async throws
        -> RecordData {
        guard isEnabledLocked else {
            logger.debug("Record collection is disabled, dropping record")
            return RecordData()
        }
        logger.verbose("Recording to stream: \(streamName)")

        return try await wrapErrorAndLog(
            operation: {
                let input = AmplifyRecordCache.RecordInput(
                    streamName: streamName,
                    partitionKey: partitionKey,
                    data: data
                )
                return try await recordClient.record(input)
            },
            logSuccess: { _, timeMs in
                logger.debug("Record completed successfully in \(timeMs)ms")
            },
            logFailure: { error, timeMs in
                logger.warn("Record failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Flushes cached records to Kinesis.
    ///
    /// Each invocation sends at most one batch per stream, limited by the Kinesis
    /// `PutRecords` constraints (up to 500 records or 10 MB per stream). If the cache
    /// Flushes all locally stored records to their respective Kinesis streams.
    ///
    /// Each flush processes all pending records in batches per stream (limited by
    /// record count and byte size). Records that fail or are retryable within a flush
    /// cycle are not retried in the same flush — they are skipped and will be picked
    /// up in the next flush cycle.
    ///
    /// Records that exceed ``Options/maxRetries`` are removed from the cache.
    ///
    /// If a flush is already in progress, the call returns immediately with
    /// `FlushData(recordsFlushed: 0, flushInProgress: true)`.
    ///
    /// - Returns: FlushData containing the number of records successfully flushed
    /// - Throws: KinesisError if flush fails due to a non-recoverable error (e.g. network failure)
    @discardableResult
    public func flush() async throws -> FlushData {
        logger.verbose("Starting flush")
        return try await wrapErrorAndLog(
            operation: {
                try await recordClient.flush()
            },
            logSuccess: { data, timeMs in
                logger.debug(
                    "Flush completed successfully in \(timeMs)ms - \(data.recordsFlushed) records flushed"
                )
            },
            logFailure: { error, timeMs in
                logger.warn("Flush failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Disables record collection and automatic flushing. Records submitted while
    /// disabled are silently dropped. Already-cached records remain in storage.
    public func disable() async {
        logger.info("Disabling record collection")
        setEnabled(false)
        await scheduler?.disable()
    }

    /// Enables record collection and automatic flushing of cached records.
    public func enable() async {
        logger.info("Enabling record collection")
        setEnabled(true)
        await scheduler?.start()
    }

    private func setEnabled(_ value: Bool) {
        isEnabledLock.lock()
        _isEnabled = value
        isEnabledLock.unlock()
    }

    /// Clears all cached records
    /// - Returns: ClearCacheData containing the number of records cleared
    /// - Throws: KinesisError if cache cannot be cleared
    @discardableResult
    public func clearCache() async throws -> ClearCacheData {
        logger.verbose("Clearing cache")
        return try await wrapErrorAndLog(
            operation: {
                try await recordClient.clearCache()
            },
            logSuccess: { data, timeMs in
                logger.debug(
                    "Clear cache completed successfully in \(timeMs)ms - \(data.recordsCleared) records cleared"
                )
            },
            logFailure: { error, timeMs in
                logger.warn("Clear cache failed in \(timeMs)ms: \(error.localizedDescription)")
            }
        )
    }

    /// Returns the underlying Kinesis client for escape hatching
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

    /// Measures and logs the execution time of an async operation, wrapping errors via ``KinesisError/from(_:)``.
    private func wrapErrorAndLog<T>(
        operation: () async throws -> T,
        logSuccess: (T, Int) -> Void,
        logFailure: (Error, Int) -> Void
    ) async throws -> T {
        var result: T!
        var error: Error?

        let start = CFAbsoluteTimeGetCurrent()
        do {
            result = try await wrapError(operation)
        } catch let caughtError {
            error = caughtError
        }
        let timeMs = Int((CFAbsoluteTimeGetCurrent() - start) * 1_000)

        if let error {
            logFailure(error, timeMs)
            throw error
        } else {
            logSuccess(result, timeMs)
            return result
        }
    }

    deinit {
        Task { [scheduler] in
            await scheduler?.disable()
        }
    }
}
