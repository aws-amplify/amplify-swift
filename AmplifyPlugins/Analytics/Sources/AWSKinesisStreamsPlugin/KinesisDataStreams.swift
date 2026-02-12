//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import InternalAmplifyCredentials
import Foundation
import AWSKinesis
import AWSClientRuntime
import SmithyIdentity

public typealias KinesisClientConfigurationProvider = (inout AWSKinesis.KinesisClient.KinesisClientConfiguration) -> Void

/// Main class for interacting with Amazon Kinesis Data Streams
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
public class KinesisDataStreams {
    private let kinesisClient: AWSKinesis.KinesisClient
    private let recordClient: RecordClient
    private let options: Options
    private let scheduler: AutoFlushScheduler

    /// Configuration options for KinesisDataStreams
    public struct Options {
        public static let defaultCacheMaxBytes: Int64 = 5 * 1024 * 1024 // 5MB
        public static let defaultMaxRecords: Int = 500
        public static let defaultMaxRetries: Int = 5

        public let cacheMaxBytes: Int64
        public let maxRecords: Int
        public let maxRetries: Int
        public let flushStrategy: FlushStrategy
        public let logger: Logger?
        public let configureClient: KinesisClientConfigurationProvider?

        public init(
            cacheMaxBytes: Int64 = defaultCacheMaxBytes,
            maxRecords: Int = defaultMaxRecords,
            maxRetries: Int = defaultMaxRetries,
            flushStrategy: FlushStrategy = .interval(),
            logger: Logger? = nil,
            configureClient: KinesisClientConfigurationProvider? = nil
        ) {
            self.cacheMaxBytes = cacheMaxBytes
            self.maxRecords = maxRecords
            self.maxRetries = maxRetries
            self.flushStrategy = flushStrategy
            self.logger = logger
            self.configureClient = configureClient
        }
    }

    /// Initializes a new KinesisDataStreams instance
    /// - Parameters:
    ///   - region: AWS region
    ///   - credentialIdentityResolver: Optional custom credential identity resolver. If nil, uses Amplify Auth credentials.
    ///   - options: Configuration options
    public init(
        region: String,
        credentialIdentityResolver: (any AWSCredentialIdentityResolver)? = nil,
        options: Options = Options()
    ) throws {
        self.options = options

        // Create Kinesis client configuration
        var clientConfig = try AWSKinesis.KinesisClient.KinesisClientConfiguration(region: region)

        // Set credentials provider - use provided resolver or default to Amplify Auth
        let resolver = credentialIdentityResolver ?? AWSAuthService().getCredentialIdentityResolver()
        clientConfig.awsCredentialIdentityResolver = resolver

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
            maxRecords: options.maxRecords,
            maxBytes: options.cacheMaxBytes
        )
        
        self.recordClient = RecordClient(
            sender: sender,
            storage: storage,
            logger: options.logger
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
    /// - Throws: RecordCacheError if the record cannot be saved
    public func record(data: Data, partitionKey: String, streamName: String) async throws {
        let input = RecordInput(
            streamName: streamName,
            partitionKey: partitionKey,
            data: data
        )

        try await recordClient.record(input)
    }

    /// Flushes all cached records to Kinesis
    /// - Returns: FlushData containing the number of records flushed
    /// - Throws: Error if flush fails
    @discardableResult
    public func flush() async throws -> FlushData {
        return try await recordClient.flush()
    }

    /// Disables data collection
    public func disable() async {
        await scheduler.disable()
    }

    /// Enables data collection
    public func enable() async {
        await scheduler.start()
    }

    /// Clears all cached records
    /// - Returns: ClearCacheData containing the number of records cleared
    /// - Throws: Error if cache cannot be cleared
    @discardableResult
    public func clearCache() async throws -> ClearCacheData {
        return try await recordClient.clearCache()
    }

    /// Returns the underlying Kinesis client for advanced use cases
    public func getKinesisClient() -> AWSKinesis.KinesisClient {
        return kinesisClient
    }
    
    deinit {
        Task { [scheduler] in
            await scheduler.disable()
        }
    }
}
