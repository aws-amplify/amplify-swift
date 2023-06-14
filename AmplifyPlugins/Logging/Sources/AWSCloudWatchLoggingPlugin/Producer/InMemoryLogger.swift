////
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// Proof-of-concept logger to aid in development.
///
/// - Tag: InMemoryLogger
class InMemoryLogger {
    
    var logLevel: Amplify.LogLevel
    let tag: String
    let logBatchSubject: PassthroughSubject<LogBatch, Never>
    var entries: [LogEntry]
    
    init(tag: String) {
        self.logLevel = .error
        self.tag = tag
        self.logBatchSubject = PassthroughSubject()
        self.entries = []
    }
    
    func remove(entries: [LogEntry]) {
        let entriesToRemove = Set(entries)
        self.entries = entries.filter { entriesToRemove.contains($0) }
    }
    
    private func appendEntry(level: Amplify.LogLevel,
                             message: @autoclosure () -> String) {
        entries.append(LogEntry(
            tag: self.tag,
            level: level,
            message: message()))
        // TODO: If enough time has passed OR enough entries have accumulated (close to CloudWatch's max batch size in bytes), publish a batch.
    }
}

extension InMemoryLogger: LogBatchProducer {
    var logBatchPublisher: AnyPublisher<LogBatch, Never> {
        return logBatchSubject.eraseToAnyPublisher()
    }
}

extension InMemoryLogger: Logger {
    func error(_ message: @autoclosure () -> String) {
        if logLevel < .error {
            return
        }
        appendEntry(level: .error, message: message())
    }
    
    func error(error: Error) {
        if logLevel < .error {
            return
        }
        appendEntry(level: .error, message: error.localizedDescription)
    }
    
    func warn(_ message: @autoclosure () -> String) {
        if logLevel < .warn {
            return
        }
        appendEntry(level: .error, message: message())
    }
    
    func info(_ message: @autoclosure () -> String) {
        if logLevel < .info {
            return
        }
        appendEntry(level: .error, message: message())
    }
    
    func debug(_ message: @autoclosure () -> String) {
        if logLevel < .debug {
            return
        }
        appendEntry(level: .error, message: message())
    }
    
    func verbose(_ message: @autoclosure () -> String) {
        if logLevel < .verbose {
            return
        }
        appendEntry(level: .error, message: message())
    }
}
