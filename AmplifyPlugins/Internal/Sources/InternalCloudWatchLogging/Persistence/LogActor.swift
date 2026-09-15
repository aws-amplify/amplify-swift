//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// Wrapper around a LogRotation to ensure thread-safe usage.
package actor LogActor {

    private let rotation: LogRotation
    private nonisolated(unsafe) let rotationSubject: PassthroughSubject<URL, Never>

    /// Initialized the actor with the given directory and fileCountLimit.
    package init(directory: URL, fileSizeLimitInBytes: Int) throws {
        self.rotation = try LogRotation(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.rotationSubject = PassthroughSubject()
    }

    /// Attempts to persist the given log entry.
    package func record(_ data: Data) throws {
        try write(data)
    }

    private func write(_ data: Data) throws {
        try rotation.ensureFileExists()
        if rotation.currentLogFile.hasSpace(for: data) {
            try rotation.currentLogFile.write(data: data)
        } else {
            let fileURL = rotation.currentLogFile.fileURL
            try rotation.rotate()
            try rotation.currentLogFile.write(data: data)
            rotationSubject.send(fileURL)
        }
    }

    package nonisolated func rotationPublisher() -> AnyPublisher<URL, Never> {
        return rotationSubject.eraseToAnyPublisher()
    }

    /// Ensures the contents of the underlying file are flushed to disk.
    package func synchronize() throws {
        try rotation.currentLogFile.synchronize()
    }

    package func getLogs() throws -> [URL] {
        return try rotation.getAllLogs()
    }

    /// Seals the active log file (when it has content) so that in-flight and subsequent writes are
    /// routed to a fresh file, then returns every *sealed* log file — that is, all logs except the
    /// active one. Flushing only sealed files avoids a race where a log written concurrently with a
    /// flush lands in the active file and is then destroyed when that file is deleted on batch
    /// completion. This mirrors the safe hand-off already used by the size-triggered rotation path.
    package func sealLogsForFlush() throws -> [URL] {
        let activePath = rotation.currentLogFile.fileURL.path
        let activeSize = ((try? FileManager.default.attributesOfItem(atPath: activePath))?[.size] as? Int) ?? 0
        if activeSize > 0 {
            // Rotating reassigns currentLogFile; the willSet on the outgoing file synchronizes and
            // closes it, so the sealed file is fully flushed to disk before we read it.
            try rotation.rotate()
        }
        let active = rotation.currentLogFile.fileURL.standardizedFileURL
        return try rotation.getAllLogs().filter { $0.standardizedFileURL != active }
    }

    package func deleteLogs() throws {
        try rotation.reset()
        try synchronize()
    }
}
