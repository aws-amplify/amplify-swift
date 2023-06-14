//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// [LogBatchProducer](x-source-tag://LogBatchProducer) implementation and logical
/// representation of a
/// [Log Rotation](https://en.wikipedia.org/wiki/Log_rotation) in which each
/// individual log aims to fit in a CloudWatch batch whose [max size limit is
/// 1MB](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/cloudwatch_limits_cwl.html)
/// at the time of this writing.
///
/// - See: [Logger](x-source-tag://Logger)
/// - See: [LogActor](x-source-tag://LogActor)
/// - See: [LogBatchProducer](x-source-tag://LogBatchProducer)
///
/// - Tag: RotatingLogger
final class RotatingLogger {

    /// - Tag: RotatingLogger.defaultSizeLimitInBytes
    static let defaultFileCountLimit: Int = 16
    
    static let defaultFileSizeLimit: UInt64 = 5000
    
    /// The [LogLevel](x-source-tag://Amplify.LogLevel) associated with the
    /// receiver.
    ///
    /// - Tag: RotatingLogger.logLevel
    var logLevel: Amplify.LogLevel
    
    private let tag: String
    private let actor: LogActor
    private let batchSubject: PassthroughSubject<LogBatch, Never>
    private var rotationSubscription: Combine.Cancellable? {
        willSet { rotationSubscription?.cancel() }
    }

    /// Initializes the logger with the given directory as its log rotation base directory.
    ///
    /// - Parameter directory: The URL of the directory to use for the log rotation.
    /// - Parameter logLevel: Amplify.LogLevel by which to filter any incomming log events.
    /// - Parameter fileCountLimit: The maximum number of log files in the log rotation.
    ///
    /// - Tag: RotatingLogger.init
    init(directory: URL,
         tag: String,
         logLevel: Amplify.LogLevel,
         fileCountLimit: Int = RotatingLogger.defaultFileCountLimit,
         fileSizeLimitInBytes: UInt64 = RotatingLogger.defaultFileSizeLimit
    ) throws {
        self.tag = tag
        self.actor = try LogActor(directory: directory,
                                  fileCountLimit: fileCountLimit,
                                  fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.batchSubject = PassthroughSubject()
        self.logLevel = logLevel
    }
    
    /// Attempts to flush the contents of the log to disk.
    ///
    /// - Tag: RotatingLogger.synchronize
    func synchronize() async throws {
        try await actor.synchronize()
    }
    
    func record(level: LogLevel, message: @autoclosure () -> String) async throws {
        if logLevel < level {
            return
        }
        if (rotationSubscription == nil) {
            let urlPublisher = await self.actor.rotationPublisher()
            let batchSubject = self.batchSubject
            rotationSubscription = urlPublisher.sink { url in
                batchSubject.send(RotatingLogBatch(url: url))
            }
        }
        let entry = LogEntry(tag: self.tag, level: level, message: message())
        try await self.actor.record(entry)
    }

    private func _record(level: LogLevel, message: @autoclosure () -> String) {
        if logLevel < level {
            return
        }
        let payload = message()
        Task {
            try await self.record(level: level, message:payload)
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
