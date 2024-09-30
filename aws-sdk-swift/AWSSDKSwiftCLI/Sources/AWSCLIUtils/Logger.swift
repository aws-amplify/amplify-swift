//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

struct Logger {
    static let standard = Logging.Logger(
        label: "com.aws.sdk.swift.cli",
        factory: {
            var logger = StreamLogHandler.standardOutput(label: $0)
            logger.logLevel = .info
            return logger
        }
    )
}

public func log(
    _ message: @autoclosure () -> Logging.Logger.Message,
    metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
) {
    log(
        level: .info,
        message(),
        metadata: metadata(),
        file: file,
        function: function,
        line: line
    )
}

public func log(
    level: Logging.Logger.Level,
    _ message: @autoclosure () -> Logging.Logger.Message,
    metadata: @autoclosure () -> Logging.Logger.Metadata? = nil,
    file: String = #fileID,
    function: String = #function,
    line: UInt = #line
) {
    Logger.standard.log(
        level: level,
        message(),
        metadata: metadata(),
        source: nil,
        file: file,
        function: function,
        line: line
    )
}
