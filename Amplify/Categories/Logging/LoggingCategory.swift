//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

final public class LoggingCategory: BaseCategory<AnyLoggingCategoryPlugin, AnalyticsPluginSelectorFactory> { }

extension LoggingCategory: LoggingCategoryClientBehavior {
    /// Logs a message at `error` level
    public func error(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        defaultPlugin.error(message(), file: file, function: function, line: line)
    }

    /// Logs the error at `error` level
    public func error(error: Error,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        defaultPlugin.error(error: error, file: file, function: function, line: line)
    }

    /// Logs a message at `warn` level
    public func warn(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        defaultPlugin.warn(message(), file: file, function: function, line: line)
    }

    /// Logs a message at `info` level
    public func info(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        defaultPlugin.info(message(), file: file, function: function, line: line)
    }

    /// Logs a message at `debug` level
    public func debug(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        defaultPlugin.debug(message(), file: file, function: function, line: line)
    }

    /// Logs a message at `verbose` level
    public func verbose(_ message: @autoclosure () -> String,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        defaultPlugin.verbose(message(), file: file, function: function, line: line)
    }
}
