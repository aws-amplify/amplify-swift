//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// Wrapper around a [LogRotation](x-source-tag://LogRotation) to ensure
/// thread-safe usage.
///
/// - See: [LogRotation](x-source-tag://LogRotation)
/// - See: [RotatingLogger](x-source-tag://RotatingLogger)
///
/// - Tag: LogActor
actor LogActor {
    
    private let rotation: LogRotation
    private let rotationSubject: PassthroughSubject<URL, Never>
    
    /// Initialized the actor with the given directory and fileCountLimit.
    ///
    /// - Tag: LogActor.init
    init(directory: URL, fileSizeLimitInBytes: Int) throws {
        self.rotation = try LogRotation(directory: directory, fileSizeLimitInBytes: fileSizeLimitInBytes)
        self.rotationSubject = PassthroughSubject()
    }
    
    /// Attempts to persist the given log entry.
    ///
    /// - Tag: LogActor.record
    func record(_ entry: LogEntry) throws {
        let data = try LogEntryCodec().encode(entry: entry)
        try write(data)
    }
    
    private func write(_ data: Data) throws {
        if rotation.currentLogFile.hasSpace(for: data) {
            try rotation.currentLogFile.write(data: data)
        } else {
            let fileURL = rotation.currentLogFile.fileURL
            try rotation.rotate()
            try rotation.currentLogFile.write(data: data)
            rotationSubject.send(fileURL)
        }
    }
    
    func rotationPublisher() -> AnyPublisher<URL, Never> {
        return rotationSubject.eraseToAnyPublisher()
    }
    
    /// Ensures the contents of the underlying file are flushed to disk.
    ///
    /// - Tag: LogActor.record
    func synchronize() throws {
        try rotation.currentLogFile.synchronize()
    }
    
    func flushLogs() throws {
        let logs = try rotation.getAllLogs()
        for log in logs {
            rotationSubject.send(log)
        }
        try rotation.reset()
    }
}
