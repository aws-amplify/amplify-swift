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
///     partitionKey: "partition-1",
///     streamName: "my-stream"
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
        isEnabledLock.withLock { _isEnabled }
    }

    /// Configuration options for AmplifyKinesisClient
    public struct Options {
        public let cacheMaxBytes: Int64

        /// How many failed sends a cached record survives: failed send `maxRetries + 1` removes it. A flush whose
        /// credentials provider throws AmplifyFoundation's `CredentialsError` (experimental SPI) counts no retry,
        /// unless the error's `disposition` is `.discard` and the cache is the region's shared one: see `flush()`.
        public let maxRetries: Int
        public let flushStrategy: FlushStrategy

        /// Optional closure for advanced customization of the underlying `KinesisClientConfiguration`.
        ///
        /// This closure is applied before the credentials resolver is set. The `credentialsProvider`
        /// passed to ``AmplifyKinesisClient/init(region:credentialsProvider:options:)`` will always
        /// take precedence over any `awsCredentialIdentityResolver` set in this closure.
        public let configureClient: AmplifyKinesisClientConfigurationProvider?

        /// Names this client's offline cache within its region. `nil`, the default, uses the cache every
        /// `AmplifyKinesisClient` of the region shares, as before this option existed.
        ///
        /// A cache holds the records of every client of the region with the same identifier, and a flush sends
        /// them all with the flushing client's credentials. So when clients are given different sessions'
        /// credentials, give each session its own identifier (an `AmplifyCognitoClient` session's
        /// `sessionId.stringValue`, say; that client is experimental SPI): otherwise one session's flush sends
        /// another's records as itself.
        ///
        /// - Any non-empty string. Identifiers that are equal as `String`s name one cache, in whichever Unicode
        ///   normalization form they are written; identifiers that differ in case are different caches. An empty
        ///   string throws `KinesisError.validation` from the initializer.
        /// - The cache's file name holds an unsalted SHA-256 of the identifier (of its canonical decomposed form,
        ///   NFD, in UTF-8), not the identifier. So any character is safe in an identifier, but do not treat the
        ///   name as hiding an email address or a user ID from someone who can list the directory.
        /// - The identifier is fixed for the client's life. Flush before you create a client with another
        ///   identifier, or with one for the first time: records cached under the old identifier, or in the
        ///   region's shared cache, stay there until a client with that identifier, or with none, flushes or
        ///   clears them.
        /// - A cache outlives its session's sign-out: its records stay until a flush sends them, a flush's
        ///   credentials failure discards them (below), or a client with that identifier calls `clearCache()`.
        ///   The emptied file is never removed: it is `kinesis_records_<region>_<that SHA-256, lowercase hex>.db`
        ///   in the Application Support directory, so delete it yourself once no client uses that identifier.
        /// - Use one client per cache in a process. Two clients over one cache file (the same identifier, or none
        ///   in the same region) each flush on their own, so both can send the same records, and one's write can
        ///   meet the other's read and fail with "database is locked" (`KinesisError.cache`).
        /// - The identifier does not name the backend. An app that switches backends at run time and uses one
        ///   identifier for both (one named session's `sessionId.stringValue`, say) flushes records cached under
        ///   the first backend with the second's credentials: include the pool in the identifier, or flush
        ///   before switching.
        /// - Only a cache with an identifier is discarded when the credentials provider says so: a flush whose
        ///   provider throws a `CredentialsError` with the `.discard` disposition (`flush()`'s
        ///   `KinesisError.credentials`) deletes everything the cache held when that flush began, records made
        ///   while no user was signed in included. Which states answer `.discard` is the provider's contract, not
        ///   this client's. The region's shared cache holds every session's records, so there the records only
        ///   count a retry, and are removed once their request has failed `maxRetries + 1` times, as after any
        ///   failed send.
        /// - A discard needs a flush while the provider answers `.discard`. Once the session vends credentials
        ///   again (as a guest, or for another user who signed in to it), a flush sends the cached records with
        ///   those credentials. So call `flush()` before, or `clearCache()` at, sign-out when records must not go
        ///   out under another principal. A session that expired cannot flush, so for it `clearCache()` at
        ///   sign-out is what keeps its records from going out under another user.
        public let cacheIdentifier: String?

        /// - Parameters:
        ///   - cacheMaxBytes: The offline cache's size limit, in bytes. 5 MB by default.
        ///   - maxRetries: See `maxRetries`. 5 by default.
        ///   - flushStrategy: When cached records are flushed automatically. Every 30 seconds by default.
        ///   - cacheIdentifier: See `cacheIdentifier`. `nil` by default: the region's shared cache.
        ///   - configureClient: See `configureClient`. `nil` by default.
        public init(
            cacheMaxBytes: Int64 = 5 * 1_024 * 1_024, // 5MB
            maxRetries: Int = 5,
            flushStrategy: FlushStrategy = .interval(),
            cacheIdentifier: String? = nil,
            configureClient: AmplifyKinesisClientConfigurationProvider? = nil
        ) {
            self.cacheMaxBytes = cacheMaxBytes
            self.maxRetries = maxRetries
            self.flushStrategy = flushStrategy
            self.configureClient = configureClient
            self.cacheIdentifier = cacheIdentifier
        }
    }

    /// Initializes a new AmplifyKinesisClient instance
    /// - Parameters:
    ///   - region: AWS region
    ///   - credentialsProvider: Foundation credential provider for AWS authentication
    ///   - options: Configuration options
    /// - Throws: `KinesisError.validation` for an empty `Options.cacheIdentifier`; `KinesisError.cache` if the
    ///   offline cache cannot be opened; the SDK's error if the client configuration cannot be built.
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

        // Inlined from the deprecated KinesisClient.init(config:)
        do {
            self.kinesisClient = try AWSKinesis.KinesisClient(config: clientConfig.toSendable())
        } catch {
            fatalError("Failed to convert deprecated configuration: \(error)")
        }

        // Create RecordClient with Kinesis-specific sender
        let sender = KinesisRecordSender(
            kinesisClient: kinesisClient,
            maxRetries: options.maxRetries
        )

        let storage: AmplifyRecordCache.SQLiteRecordStorage
        do {
            storage = try AmplifyRecordCache.SQLiteRecordStorage(
                dbPrefix: "kinesis_records",
                identifier: region,
                cacheIdentifier: options.cacheIdentifier,
                maxRecords: maxRecordsPerStream,
                cacheMaxBytes: options.cacheMaxBytes,
                maxRecordSizeBytes: maxRecordSizeBytes,
                maxBytesPerStream: maxBytesPerStream,
                maxPartitionKeyLength: maxPartitionKeyLength
            )
        } catch {
            // The cache's own errors are package types: callers get `KinesisError`.
            throw KinesisError.from(error)
        }

        self.recordClient = AmplifyRecordCache.RecordClient(
            sender: sender,
            storage: storage,
            maxRetries: options.maxRetries,
            ownsCache: options.cacheIdentifier != nil
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
    /// **When the credentials provider throws AmplifyFoundation's `CredentialsError`** (an `AmplifyCognitoClient`
    /// session's provider does; both are experimental SPI), the flush stops there and throws
    /// ``KinesisError/credentials(_:_:_:)``, with that error underneath. What happens to the records follows the
    /// error's `disposition`:
    /// - `.retryAfterReauthentication` (the session expired), `.retryWithBackoff` and `.failLoudly`: the records
    ///   are kept, with no retry counted, and sent by a later flush once the provider vends credentials again.
    ///   Kept this way they do not expire through ``Options/maxRetries``, so the cache can fill to
    ///   ``Options/cacheMaxBytes``, after which `record` throws ``KinesisError/cacheLimitExceeded(_:_:_:)``.
    /// - `.discard` (the provider has no user to wait for; which states answer it is the provider's contract):
    ///   with ``Options/cacheIdentifier`` set, the first such flush removes everything the cache held when the
    ///   flush began, records made while no user was signed in included; records added during the flush are
    ///   kept. Without an identifier nothing is removed at once, since the region's shared cache holds every
    ///   session's records: the records of the request that failed count a retry, exactly as after any failed
    ///   send, and are removed once that request has failed ``Options/maxRetries`` + 1 times.
    ///
    /// While failures that keep the records repeat, the automatic flush backs off: its interval doubles with
    /// each such flush in a row, up to 15 minutes (an interval already longer than that is left alone). The
    /// back-off ends when a flush completes, when a send fails for another reason, when the provider answers
    /// `.discard` (which never backs off), or when `enable()` restarts the schedule. A wait already under way is
    /// not shortened: call `enable()` once the session can vend credentials again (after a sign-in, say), but
    /// only on a client that is enabled, since it also turns collection back on for a client the app disabled.
    /// Any other error from the provider is a failed send, as before: ``KinesisError/unknown(_:_:_:)``, and a
    /// retry counted.
    ///
    /// A cancelled flush whose send fails counts no retry and applies no disposition: nothing is discarded.
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
        isEnabledLock.withLock { _isEnabled = value }
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
