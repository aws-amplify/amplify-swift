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
import AWSFirehose
import Foundation
import SmithyIdentity

// Re-export shared types so `import AmplifyFirehoseClient` is sufficient for consumers.
public typealias RecordData = AmplifyRecordCache.RecordData
public typealias FlushData = AmplifyRecordCache.FlushData
public typealias ClearCacheData = AmplifyRecordCache.ClearCacheData
public typealias FlushStrategy = AmplifyRecordCache.FlushStrategy

public typealias AmplifyFirehoseClientConfigurationProvider = (
    inout AWSFirehose.FirehoseClient.FirehoseClientConfiguration
) -> Void

/// Firehose supports up to 500 records per PutRecordBatch request.
/// See [the docs](https://docs.aws.amazon.com/firehose/latest/APIReference/API_PutRecordBatch.html)
private let maxRecordsPerStream = 500

/// Maximum size of a single record (data blob only) in bytes (1,000 KiB).
/// See [PutRecordBatch Record](https://docs.aws.amazon.com/firehose/latest/APIReference/API_Record.html)
private let maxRecordSizeBytes: Int64 = 1_000 * 1_024

/// Maximum total payload size per PutRecordBatch request in bytes (4 MiB).
/// See [PutRecordBatch](https://docs.aws.amazon.com/firehose/latest/APIReference/API_PutRecordBatch.html)
private let maxBytesPerStream: Int64 = 4 * 1_024 * 1_024

/// A client for sending data to Amazon Data Firehose delivery streams.
///
/// Provides automatic batching, retry logic, and local caching for high-throughput
/// data streaming to Firehose with configurable flush strategies.
///
/// Example usage:
/// ```swift
/// let firehose = try AmplifyFirehoseClient(
///     region: "us-east-1",
///     credentialsProvider: credentialsProvider
/// )
///
/// // Record data
/// let result = try await firehose.record(
///     data: "Hello Firehose".data(using: .utf8)!,
///     streamName: "my-delivery-stream"
/// )
///
/// // Flush cached records
/// let flushResult = try await firehose.flush()
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public class AmplifyFirehoseClient {
    private let firehoseClient: AWSFirehose.FirehoseClient
    private let recordClient: AmplifyRecordCache.RecordClient
    private let options: Options
    private let scheduler: AmplifyRecordCache.AutoFlushScheduler?
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AmplifyFirehoseClient.self)
    private let isEnabledLock = NSLock()
    private var _isEnabled = true

    private var isEnabledLocked: Bool {
        isEnabledLock.lock()
        defer { isEnabledLock.unlock() }
        return _isEnabled
    }

    /// Configuration options for AmplifyFirehoseClient
    public struct Options {
        public let cacheMaxBytes: Int64
        public let maxRetries: Int
        public let flushStrategy: FlushStrategy

        /// Optional closure for advanced customization of the underlying `FirehoseClientConfiguration`.
        ///
        /// This closure is applied before the credentials resolver is set. The `credentialsProvider`
        /// passed to ``AmplifyFirehoseClient/init(region:credentialsProvider:options:)`` will always
        /// take precedence over any `awsCredentialIdentityResolver` set in this closure.
        public let configureClient: AmplifyFirehoseClientConfigurationProvider?

        public init(
            cacheMaxBytes: Int64 = 5 * 1_024 * 1_024, // 5MB
            maxRetries: Int = 5,
            flushStrategy: FlushStrategy = .interval(),
            configureClient: AmplifyFirehoseClientConfigurationProvider? = nil
        ) {
            self.cacheMaxBytes = cacheMaxBytes
            self.maxRetries = maxRetries
            self.flushStrategy = flushStrategy
            self.configureClient = configureClient
        }
    }

    /// Initializes a new AmplifyFirehoseClient instance
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

        // Create Firehose client configuration
        var clientConfig = try AWSFirehose.FirehoseClient.FirehoseClientConfiguration(region: region)

        if let configureClient = options.configureClient {
            configureClient(&clientConfig)
        }
        clientConfig.awsCredentialIdentityResolver = FoundationToSDKCredentialsAdapter(
            provider: credentialsProvider
        )

        // Wrap the default HTTP engine to append firehose user agent metadata
        clientConfig.httpClientEngine = UserAgentClientEngine(
            target: clientConfig.httpClientEngine,
            additionalMetadata: ["md/amplify-firehose"]
        )

        self.firehoseClient = AWSFirehose.FirehoseClient(config: clientConfig)

        // Create RecordClient with Firehose-specific sender
        let sender = FirehoseRecordSender(
            firehoseClient: firehoseClient,
            maxRetries: options.maxRetries
        )

        let storage = try AmplifyRecordCache.SQLiteRecordStorage(
            dbPrefix: "firehose_records",
            identifier: region,
            maxRecords: maxRecordsPerStream,
            cacheMaxBytes: options.cacheMaxBytes,
            maxRecordSizeBytes: maxRecordSizeBytes,
            maxBytesPerStream: maxBytesPerStream,
            maxPartitionKeyLength: nil
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

    /// Records data to a Firehose delivery stream
    /// - Parameters:
    ///   - data: The data to record
    ///   - streamName: The name of the Firehose delivery stream
    /// - Returns: RecordData containing the result of the record operation
    /// - Throws: FirehoseError if the record cannot be saved
    @discardableResult
    public func record(data: Data, streamName: String) async throws -> RecordData {
        guard isEnabledLocked else {
            logger.debug("Record collection is disabled, dropping record")
            return RecordData()
        }
        logger.verbose("Recording to delivery stream: \(streamName)")

        return try await wrapErrorAndLog(
            operation: {
                let input = AmplifyRecordCache.RecordInput(
                    streamName: streamName,
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

    /// Flushes all locally stored records to their respective Firehose delivery streams.
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
    /// - Throws: FirehoseError if flush fails due to a non-recoverable error (e.g. network failure)
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
    /// - Throws: FirehoseError if cache cannot be cleared
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

    /// Returns the underlying Firehose client for escape hatching
    public func getFirehoseClient() -> AWSFirehose.FirehoseClient {
        return firehoseClient
    }

    /// Wraps an async operation, converting internal errors to FirehoseError via ``FirehoseError/from(_:)``.
    private func wrapError<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as FirehoseError {
            throw error
        } catch {
            throw FirehoseError.from(error)
        }
    }

    /// Measures and logs the execution time of an async operation, wrapping errors via ``FirehoseError/from(_:)``.
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
