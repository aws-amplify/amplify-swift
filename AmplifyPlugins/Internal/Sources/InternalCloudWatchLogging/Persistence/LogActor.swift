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
    private let rotationSubject: PassthroughSubject<URL, Never>

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

    package func rotationPublisher() -> AnyPublisher<URL, Never> {
        return rotationSubject.eraseToAnyPublisher()
    }

    /// Ensures the contents of the underlying file are flushed to disk.
    package func synchronize() throws {
        try rotation.currentLogFile.synchronize()
    }

    package func getLogs() throws -> [URL] {
        return try rotation.getAllLogs()
    }

    package func deleteLogs() throws {
        try rotation.reset()
        try synchronize()
    }
}
