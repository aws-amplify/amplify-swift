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

    let tag: String
    let userIdentifier: String?
    let logger: RotatingLogger

    init(tag: String, logLevel: LogLevel, userIdentifier: String? = nil) throws {
        self.tag = tag
        self.userIdentifier = userIdentifier
        self.logger = try Self.createLogger(tag: tag,
                                            logLevel: logLevel,
                                            userIdentifier: userIdentifier)
    }

    private static func createLogger(tag: String, logLevel: LogLevel, userIdentifier: String?, fileManager: FileManager = .default) throws -> RotatingLogger {
        let directory = try directory(for: tag, userIdentifier: userIdentifier)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        try (directory as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
        return try RotatingLogger(directory: directory, tag: tag, logLevel: logLevel)
    }

    private static func directory(for tag: String, userIdentifier: String?, fileManager: FileManager = .default) throws -> URL {
        let normalizedUserIdentifier = try normalized(userIdentifier: userIdentifier)
        let normalizedTag = tag.trimmingCharacters(in: .alphanumerics.inverted).lowercased()
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

        guard let userIdentifierData = userIdentifier.data(using: .utf8) else {
            throw AWSCloudWatchLoggingError.sessionInternalErrorForUserId
        }

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
    static let sessionInternalErrorForUserId = AWSCloudWatchLoggingError(errorDescription: "Internal error while attempting to interpret userId", recoverySuggestion: "")
}
