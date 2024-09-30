//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ArgumentParser

public extension Process {
    /// Creates a process using `/usr/bin/env` as the executable
    /// This makes it easy to create a process  for any command, as long as the corresponding executable exists in the PATH.
    ///
    /// - Parameter argsList: The command arguments, such as `["swift", "build"]`
    convenience init(_ argsList: [String]) {
        self.init()
        self.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        self.arguments = argsList
    }
    
    /// Creates a process using `/usr/bin/env` as the executable
    /// This makes it easy to create a process  for any command, as long as the corresponding executable exists in the PATH.
    ///
    /// - Parameter args: The command arguments, such as `"swift", "build"`
    convenience init(_ args: String...) {
        self.init(Array(args))
    }
    
    /// Returns the executable and arguments combined as a string
    var commandString: String {
        let items = [urlPath(executableURL)] + (arguments ?? [])
        return items
            .compactMap { $0 }
            .joined(separator: " ")
    }
}

public func _run(_ process: Process) throws {
    // If debug and we have a non-nil test runner, then use that
    // This allows developers to intercept processes when they run to assert that it is the expected process
    #if DEBUG
    if let testRunner = ProcessRunner.testRunner {
        try testRunner.run(process)
        return
    }
    #endif
    try ProcessRunner.standard.run(process)
}

public func _runReturningStdOut(_ process: Process) throws -> String? {
    // If debug and we have a non-nil test runner, then use that
    // This allows developers to intercept processes when they run to assert that it is the expected process
    #if DEBUG
    if let testRunner = ProcessRunner.testRunner {
        try testRunner.run(process)
        return nil
    }
    #endif
    let stdOut = Pipe()
    process.standardOutput = stdOut
    
    try _run(process)
    process.waitUntilExit()
    
    let data = try stdOut.fileHandleForReading.readToEnd() ?? Data()
    return String(data: data, encoding: .utf8)
}

/// A simple struct that runs a process
public struct ProcessRunner {

    public init(_ run: @escaping (Process) throws -> Void) {
        self.run = run
    }

    public let run: (Process) throws -> Void
    
    /// Creates the standard runner to be used by the release version of this CLI
    ///
    /// Runs the process and prints out the process's full command.
    public static let standard = ProcessRunner { process in
        log(level: .debug, "Running process: \(process.commandString)")
        try process.run()
        process.waitUntilExit()
        let exitCode = ExitCode(process.terminationStatus)
        if !exitCode.isSuccess {
            throw exitCode
        }
    }
    
    #if DEBUG
    // Set this to a non-nil value in tests to intercept when a process is run
    public static var testRunner: ProcessRunner? = nil
    #endif
}
