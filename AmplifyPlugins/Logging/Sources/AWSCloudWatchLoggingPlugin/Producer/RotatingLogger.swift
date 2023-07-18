//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

final class RotatingLogger {
    
    var logLevel: Amplify.LogLevel
    
    private let category: String
    private let namespace: String?
    private let actor: LogActor
    private let batchSubject: PassthroughSubject<LogBatch, Never>
    private var rotationSubscription: Combine.Cancellable? {
        willSet { rotationSubscription?.cancel() }
    }

    /// Initializes the logger with the given directory as its log rotation base directory.
    ///
    /// - Parameter directory: The URL of the directory to use for the log rotation.
    /// - Parameter logLevel: Amplify.LogLevel by which to filter any incomming log events.
    init(directory: URL,
         category: String,
         namespace: String?,
         logLevel: Amplify.LogLevel,
         fileSizeLimitInBytes: Int
    ) throws {
        self.category = category
        self.namespace = namespace
        self.actor = try LogActor(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.batchSubject = PassthroughSubject()
        self.logLevel = logLevel
    }
    
    /// Attempts to flush the contents of the log to disk.
    func synchronize() async throws {
        try await actor.synchronize()
    }
    
    func flushLogs() async throws {
        try await setupSubscription()
        try await actor.flushLogs()
    }
    
    func record(level: LogLevel, message: @autoclosure () -> String) async throws {
        try await setupSubscription()
        let entry = LogEntry(category: self.category, namespace: self.namespace, level: level, message: message())
        try await self.actor.record(entry)
    }
    
    private func setupSubscription() async throws {
        if (rotationSubscription == nil) {
            let rotationPublisher = await self.actor.rotationPublisher()
            rotationSubscription = rotationPublisher.sink { [weak self] url in
                guard let self = self else { return }
                self.batchSubject.send(RotatingLogBatch(url: url))
            }
        }
    }

    private func _record(level: LogLevel, message: @autoclosure () -> String) {
        let payload = message()
        Task {
            do {
                try await self.record(level: level, message:payload)
            } catch {
                let payload = HubPayload(
                    eventName: HubPayload.EventName.Logging.writeLogFailure,
                    context: error.localizedDescription,
                    data: payload)
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
