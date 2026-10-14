//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@preconcurrency import Combine
import Foundation
import InternalCloudWatchLogging

/// - Note: `@unchecked Sendable`: `logLevel` is the only mutable state, and the owning session
///   controller writes it under its lock.
final class RotatingLogger: @unchecked Sendable {

    var logLevel: Amplify.LogLevel

    private let category: String
    private let namespace: String?
    private let actor: LogActor
    private let batchSubject: PassthroughSubject<LogBatch, Never>
    private let rotationSubscription: Combine.Cancellable

    /// Initializes the logger with the given directory as its log rotation base directory.
    ///
    /// - Parameter directory: The URL of the directory to use for the log rotation.
    /// - Parameter logLevel: Amplify.LogLevel by which to filter any incomming log events.
    init(
        directory: URL,
        category: String,
        namespace: String?,
        logLevel: Amplify.LogLevel,
        fileSizeLimitInBytes: Int
    ) throws {
        self.category = category
        self.namespace = namespace
        let logActor = try LogActor(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        let batchSubject = PassthroughSubject<LogBatch, Never>()
        self.actor = logActor
        self.batchSubject = batchSubject
        self.logLevel = logLevel
        // Subscribe once, eagerly, so concurrent first records can't race to create the subscription.
        self.rotationSubscription = logActor.rotationPublisher().sink { url in
            batchSubject.send(RotatingLogBatch(url: url))
        }
    }

    /// Attempts to flush the contents of the log to disk.
    func synchronize() async throws {
        try await actor.synchronize()
    }

    func getLogBatches() async throws -> [RotatingLogBatch] {
        let logs = try await actor.getLogs()
        return logs.map {RotatingLogBatch(url: $0)}
    }

    func resetLogs() async throws {
        try await actor.deleteLogs()
    }

    /// Stops writing; see `LogActor.close()`.
    func close() {
        actor.close()
    }

    /// Stops writing and discards the logs; see `LogActor.discardLogs()`.
    func discardLogs() throws {
        try actor.discardLogs()
    }

    func record(level: LogLevel, message: @autoclosure () -> String) async throws {
        let entry = LogEntry(category: category, namespace: namespace, level: level, message: message())
        let data = try LogEntryCodec().encode(entry: entry)
        try await actor.record(data)
    }

    private func _record(level: LogLevel, message: @autoclosure () -> String) {
        let payload = message()
        Task {
            do {
                try await self.record(level: level, message: payload)
            } catch {
                let payload = HubPayload(
                    eventName: HubPayload.EventName.Logging.writeLogFailure,
                    context: error.localizedDescription,
                    data: payload
                )
                Amplify.Hub.dispatch(to: HubChannel.logging, payload: payload)
            }
        }
    }
}

extension RotatingLogger: LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> {
        return batchSubject.eraseToAnyPublisher()
    }
}

extension RotatingLogger: Logger {

    func error(_ message: @autoclosure () -> String) {
        _record(level: .error, message: message())
    }

    func error(error: Error) {
        let message = String(describing: error)
        _record(level: .error, message: message)
    }

    func warn(_ message: @autoclosure () -> String) {
        _record(level: .warn, message: message())
    }

    func info(_ message: @autoclosure () -> String) {
        _record(level: .info, message: message())
    }

    func debug(_ message: @autoclosure () -> String) {
        _record(level: .debug, message: message())
    }

    func verbose(_ message: @autoclosure () -> String) {
        _record(level: .verbose, message: message())
    }
}
