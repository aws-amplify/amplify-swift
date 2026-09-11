//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Combine
import Foundation
import InternalCloudWatchLogging

final class RotatingLogger: @unchecked Sendable {

    private let namespace: String
    private let logActor: LogActor
    private let batchSubject: PassthroughSubject<LogBatch, Never>
    private let eventSubject: PassthroughSubject<LoggingEvent, Never>?
    private let rotationSubscription: Combine.Cancellable

    init(
        directory: URL,
        namespace: String,
        fileSizeLimitInBytes: Int,
        eventSubject: PassthroughSubject<LoggingEvent, Never>? = nil
    ) throws {
        self.namespace = namespace
        self.logActor = try LogActor(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        let batchSubject = PassthroughSubject<LogBatch, Never>()
        self.batchSubject = batchSubject
        self.eventSubject = eventSubject
        // Subscribe once, eagerly, so two concurrent first records can't create competing subscriptions.
        self.rotationSubscription = logActor.rotationPublisher().sink { url in
            batchSubject.send(RotatingLogBatch(url: url))
        }
    }

    func synchronize() async throws {
        try await logActor.synchronize()
    }

    func getLogBatches() async throws -> [RotatingLogBatch] {
        do {
            let logs = try await logActor.getLogs()
            return logs.map { RotatingLogBatch(url: $0) }
        } catch {
            throw CloudWatchError.storage(
                "Failed to retrieve log batches from local storage",
                "This is an internal error. Please file a bug report.",
                error
            )
        }
    }

    func resetLogs() async throws {
        do {
            try await logActor.deleteLogs()
        } catch {
            throw CloudWatchError.storage(
                "Failed to reset local logs",
                "This is an internal error. Please file a bug report.",
                error
            )
        }
    }

    func record(level: LogLevel, message: @autoclosure () -> String) async throws {
        let entry = LogEntry(namespace: namespace, level: level, message: message())
        let data = try LogEntryCodec().encode(entry: entry)
        try await logActor.record(data)
    }

    func _record(level: LogLevel, message: @autoclosure () -> String) {
        let payload = message()
        Task { [weak self] in
            do {
                try await self?.record(level: level, message: payload)
            } catch {
                self?.eventSubject?.send(.writeLogFailure(context: error.localizedDescription, error: error))
            }
        }
    }

    func error(_ message: @autoclosure () -> String) { _record(level: .error, message: message()) }
    func error(error: Error) { _record(level: .error, message: String(describing: error)) }
    func warn(_ message: @autoclosure () -> String) { _record(level: .warn, message: message()) }
    func info(_ message: @autoclosure () -> String) { _record(level: .info, message: message()) }
    func debug(_ message: @autoclosure () -> String) { _record(level: .debug, message: message()) }
    func verbose(_ message: @autoclosure () -> String) { _record(level: .verbose, message: message()) }
}

extension RotatingLogger: LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> {
        return batchSubject.eraseToAnyPublisher()
    }
}
