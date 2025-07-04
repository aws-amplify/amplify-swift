//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import CryptoKit
import Foundation

/// Responsible for containg the logger of an individual **tag**  and **user session** (wheter logged in
/// or not) pair.
///
/// - Tag: CloudWatchLogSession
final class AWSCloudWatchLoggingSession {

    let category: String
    let namespace: String?
    let userIdentifier: String?
    let logger: RotatingLogger

    init(category: String, namespace: String?, logLevel: LogLevel, userIdentifier: String? = nil, localStoreMaxSizeInMB: Int) throws {
        self.category = category
        self.namespace = namespace
        self.userIdentifier = userIdentifier
        self.logger = try Self.createLogger(category: category,
                                            namespace: namespace,
                                            logLevel: logLevel,
                                            userIdentifier: userIdentifier,
                                            localStoreMaxSizeInMB: localStoreMaxSizeInMB)
    }

    private static func createLogger(
        category: String,
        namespace: String?,
        logLevel: LogLevel,
        userIdentifier: String?,
        localStoreMaxSizeInMB: Int,
        fileManager: FileManager = .default
    ) throws -> RotatingLogger {
        let directory = try directory(for: category, userIdentifier: userIdentifier)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try (directory as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        
        // Calculate appropriate file size limit (individual file, not total cache)
        // Use a reasonable file size limit that's a fraction of the total cache size
        // Ensure it meets the minimum requirement of 1KB
        let totalCacheSizeInBytes = localStoreMaxSizeInMB * 1048576
        let fileSizeLimitInBytes = max(
            LogRotation.minimumFileSizeLimitInBytes,
            totalCacheSizeInBytes / LogRotation.fileCountLimit
        )

        return try RotatingLogger(directory: directory,
                                  category: category,
                                  namespace: namespace,
                                  logLevel: logLevel,
                                  fileSizeLimitInBytes: fileSizeLimitInBytes)
    }

    private static func directory(for category: String, userIdentifier: String?, fileManager: FileManager = .default) throws -> URL {
        let normalizedUserIdentifier = try normalized(userIdentifier: userIdentifier)
        let normalizedTag = category.trimmingCharacters(in: .alphanumerics.inverted).lowercased()
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? NSTemporaryDirectory()
        let directory = documents.appendingPathComponent("amplify")
                                 .appendingPathComponent("logging")
                                 .appendingPathComponent(normalizedUserIdentifier)
                                 .appendingPathComponent(normalizedTag)
        print("Using log directory: \(directory)")
        return URL(fileURLWithPath: directory)
    }

    private static func normalized(userIdentifier: String?) throws -> String {
        guard let userIdentifier = userIdentifier else {
            return "guest"
        }

        let userIdentifierData = Data(userIdentifier.utf8)
        var hash = SHA256()
        hash.update(data: userIdentifierData)

        let digest = hash.finalize()
        return Array(digest.makeIterator()).map { String(format: "%02X", $0) }.joined()
    }
}

extension AWSCloudWatchLoggingSession: LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> {
        return logger.logBatchPublisher
    }
}

extension AWSCloudWatchLoggingError {
    static let sessionInternalErrorForUserId = AWSCloudWatchLoggingError(
        errorDescription: "Internal error while attempting to interpret userId", recoverySuggestion: "")
}
