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

final class RotatingLogger {

    var logLevel: LogLevel

    private let namespace: String
    private let logActor: LogActor
    private let batchSubject: PassthroughSubject<LogBatch, Never>
    private let eventSubject: PassthroughSubject<LoggingEvent, Never>?
    private var rotationSubscription: Combine.Cancellable? {
        willSet { rotationSubscription?.cancel() }
    }

    init(
        directory: URL,
        namespace: String,
        logLevel: LogLevel,
        fileSizeLimitInBytes: Int,
        eventSubject: PassthroughSubject<LoggingEvent, Never>? = nil
    ) throws {
        self.namespace = namespace
        self.logActor = try LogActor(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.batchSubject = PassthroughSubject()
        self.logLevel = logLevel
        self.eventSubject = eventSubject
    }

    func synchronize() async throws {
        try await logActor.synchronize()
    }

    func getLogBatches() async throws -> [RotatingLogBatch] {
        let logs = try await logActor.getLogs()
        return logs.map { RotatingLogBatch(url: $0) }
    }

    func resetLogs() async throws {
        try await logActor.deleteLogs()
    }

    func record(level: LogLevel, message: @autoclosure () -> String) async throws {
        try await setupSubscription()
        let entry = LogEntry(namespace: namespace, level: level, message: message())
        let data = try LogEntryCodec().encode(entry: entry)
        try await logActor.record(data)
    }

    private func setupSubscription() async throws {
        if rotationSubscription == nil {
            let rotationPublisher = await logActor.rotationPublisher()
            rotationSubscription = rotationPublisher.sink { [weak self] url in
                guard let self else { return }
                batchSubject.send(RotatingLogBatch(url: url))
            }
        }
    }

    func _record(level: LogLevel, message: @autoclosure () -> String) {
        let payload = message()
        Task {
            do {
                try await self.record(level: level, message: payload)
            } catch {
                eventSubject?.send(.writeLogFailure(context: error.localizedDescription, error: error))
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
