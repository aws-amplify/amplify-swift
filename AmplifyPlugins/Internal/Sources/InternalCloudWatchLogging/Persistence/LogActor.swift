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

    private static let discardedDirectoryPrefix = ".discarded-"

    private let rotation: LogRotation
    private nonisolated(unsafe) let rotationSubject: PassthroughSubject<URL, Never>
    private nonisolated let directory: URL
    private nonisolated let closedLock = NSLock()
    /// Guarded by `closedLock`, because `close()` is called from outside the actor.
    private nonisolated(unsafe) var _isClosed = false

    /// Initialized the actor with the given directory and fileCountLimit.
    package init(directory: URL, fileSizeLimitInBytes: Int) throws {
        let rotation = try LogRotation(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.rotation = rotation
        self.rotationSubject = PassthroughSubject()
        self.directory = rotation.directory
    }

    private nonisolated var isClosed: Bool {
        closedLock.lock()
        defer { closedLock.unlock() }
        return _isClosed
    }

    /// Leaves the directory to the next `LogActor` there: queued records are dropped, and no logs are listed.
    package nonisolated func close() {
        closedLock.lock()
        _isClosed = true
        closedLock.unlock()
    }

    /// Closes the actor and moves its directory aside, so the next `LogActor` there starts empty, then deletes it in the background.
    package nonisolated func discardLogs() throws {
        close()
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else { return }
        let parent = directory.deletingLastPathComponent()
        let discarded = parent.appendingPathComponent(Self.discardedDirectoryPrefix + UUID().uuidString)
        try fileManager.moveItem(at: directory, to: discarded)
        Task.detached(priority: .utility) {
            Self.removeDiscardedDirectories(in: parent)
        }
    }

    /// Also removes directories left behind when the app stopped before an earlier deletion finished.
    private static func removeDiscardedDirectories(in parent: URL) {
        let fileManager = FileManager.default
        let names = (try? fileManager.contentsOfDirectory(atPath: parent.path)) ?? []
        for name in names where name.hasPrefix(discardedDirectoryPrefix) {
            try? fileManager.removeItem(at: parent.appendingPathComponent(name))
        }
    }

    /// Attempts to persist the given log entry.
    package func record(_ data: Data) throws {
        guard !isClosed else { return }
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
        guard !isClosed else { return [] }
        return try rotation.getAllLogs()
    }

    /// Seals the active log file (when it has content) so that in-flight and subsequent writes are
    /// routed to a fresh file, then returns every *sealed* log file — that is, all logs except the
    /// active one. Flushing only sealed files avoids a race where a log written concurrently with a
    /// flush lands in the active file and is then destroyed when that file is deleted on batch
    /// completion. This mirrors the safe hand-off already used by the size-triggered rotation path.
    package func sealLogsForFlush() throws -> [URL] {
        guard !isClosed else { return [] }
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
        guard !isClosed else { return }
        try rotation.reset()
        try synchronize()
    }
}
