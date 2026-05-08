//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import CryptoKit
import AmplifyFoundation
import Foundation
import InternalCloudWatchLogging

/// Responsible for containing the logger of an individual namespace and user session pair.
final class CloudWatchLoggingSession {

    let namespace: String
    let userIdentifier: String?
    let logger: RotatingLogger

    init(namespace: String, logLevel: LogLevel, userIdentifier: String? = nil, localStoreMaxSizeInMB: Int, eventSubject: PassthroughSubject<LoggingEvent, Never>? = nil) throws {
        self.namespace = namespace
        self.userIdentifier = userIdentifier
        self.logger = try Self.createLogger(
            namespace: namespace,
            logLevel: logLevel,
            userIdentifier: userIdentifier,
            localStoreMaxSizeInMB: localStoreMaxSizeInMB,
            eventSubject: eventSubject
        )
    }

    private static func createLogger(
        namespace: String,
        logLevel: LogLevel,
        userIdentifier: String?,
        localStoreMaxSizeInMB: Int,
        fileManager: FileManager = .default,
        eventSubject: PassthroughSubject<LoggingEvent, Never>? = nil
    ) throws -> RotatingLogger {
        let directory = try directory(for: namespace, userIdentifier: userIdentifier)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try (directory as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)

        let totalCacheSizeInBytes = localStoreMaxSizeInMB * 1_048_576
        let fileSizeLimitInBytes = max(
            LogRotation.minimumFileSizeLimitInBytes,
            totalCacheSizeInBytes / LogRotation.fileCountLimit
        )

        return try RotatingLogger(
            directory: directory,
            namespace: namespace,
            logLevel: logLevel,
            fileSizeLimitInBytes: fileSizeLimitInBytes,
            eventSubject: eventSubject
        )
    }

    private static func directory(for namespace: String, userIdentifier: String?, fileManager: FileManager = .default) throws -> URL {
        let normalizedUserIdentifier = normalized(userIdentifier: userIdentifier)
        let normalizedTag = namespace.trimmingCharacters(in: .alphanumerics.inverted).lowercased()
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
        let directory = documents.appendingPathComponent("amplify")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent(normalizedUserIdentifier)
                                 .appendingPathComponent(normalizedTag)
        return URL(fileURLWithPath: directory)
    }

    private static func normalized(userIdentifier: String?) -> String {
        guard let userIdentifier else {
            return "guest"
        }

        let userIdentifierData = Data(userIdentifier.utf8)
        var hash = SHA256()
        hash.update(data: userIdentifierData)

        let digest = hash.finalize()
        return Array(digest.makeIterator()).map { String(format: "%02X", $0) }.joined()
    }
}

extension CloudWatchLoggingSession: LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> {
        return logger.logBatchPublisher
    }
}
