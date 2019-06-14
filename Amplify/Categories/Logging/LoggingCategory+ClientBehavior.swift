//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension LoggingCategory: LoggingCategoryClientBehavior {
    private func plugin(from selector: LoggingPluginSelector) -> LoggingCategoryPlugin {
        guard let key = selector.selectedPluginKey else {
            preconditionFailure(
                """
                \(String(describing: selector)) did not set `selectedPluginKey` for the function `\(#function)`
                """)
        }
        guard let plugin = try? getPlugin(for: key) else {
            preconditionFailure(
                """
                \(String(describing: selector)) set `selectedPluginKey` to \(key) for the function `\(#function)`,
                but there is no plugin added for that key.
                """)
        }
        return plugin
    }

    /// Logs a message at `error` level
    public func error(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.error(message(), file: file, function: function, line: line)
        case .selector(let selector):
            selector.error(message(), file: file, function: function, line: line)
            plugin(from: selector).error(message(), file: file, function: function, line: line)
        }
    }

    /// Logs the error at `error` level
    public func error(error: Error,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.error(error: error, file: file, function: function, line: line)
        case .selector(let selector):
            selector.error(error: error, file: file, function: function, line: line)
            plugin(from: selector).error(error: error, file: file, function: function, line: line)
        }
    }

    /// Logs a message at `warn` level
    public func warn(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.warn(message(), file: file, function: function, line: line)
        case .selector(let selector):
            selector.warn(message(), file: file, function: function, line: line)
            plugin(from: selector).warn(message(), file: file, function: function, line: line)
        }
    }

    /// Logs a message at `info` level
    public func info(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.info(message(), file: file, function: function, line: line)
        case .selector(let selector):
            selector.info(message(), file: file, function: function, line: line)
            plugin(from: selector).info(message(), file: file, function: function, line: line)
        }
    }

    /// Logs a message at `debug` level
    public func debug(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.debug(message(), file: file, function: function, line: line)
        case .selector(let selector):
            selector.debug(message(), file: file, function: function, line: line)
            plugin(from: selector).debug(message(), file: file, function: function, line: line)
        }
    }

    /// Logs a message at `verbose` level
    public func verbose(_ message: @autoclosure () -> String,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        switch pluginOrSelector {
        case .plugin(let plugin):
            plugin.verbose(message(), file: file, function: function, line: line)
        case .selector(let selector):
            selector.verbose(message(), file: file, function: function, line: line)
            plugin(from: selector).verbose(message(), file: file, function: function, line: line)
        }
    }

}
