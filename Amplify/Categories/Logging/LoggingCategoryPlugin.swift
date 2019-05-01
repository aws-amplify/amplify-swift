//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The behavior that all LoggingPlugins provide
public protocol LoggingCategoryPlugin: Plugin, LoggingCategoryClientBehavior
    where PluginMarker == CategoryMarker.Logging { }

/// A type-erasing wrapper to allow for heterogeneous collections of plugins
public struct AnyLoggingCategoryPlugin: LoggingCategoryPlugin, PluginInitializable {
    public typealias PluginInitializableMarker = CategoryMarker.Logging
    
    // Generic plugin behaviors
    public let key: PluginKey
    private let _configure: (Any) throws -> Void
    private let _reset: () -> Void

    // Holder for client-specific behaviors
    private let clientBehavior: LoggingCategoryClientBehavior

    public init<P: Plugin>(instance: P) where PluginInitializableMarker == P.PluginMarker {
        guard let clientBehavior = instance as? LoggingCategoryClientBehavior else {
            preconditionFailure("Plugin does not conform to LoggingCategoryClientBehavior")
        }

        self.clientBehavior = clientBehavior

        key = instance.key
        _configure = instance.configure
        _reset = instance.reset
    }

    public func configure(using configuration: Any) throws {
        try _configure(configuration)
    }

    public func reset() {
        _reset()
    }

    // MARK: - Client behavior

    public func error(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        clientBehavior.error(message(), file: file, function: function, line: line)
    }

    public func error(error: Error,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        clientBehavior.error(error: error, file: file, function: function, line: line)
    }

    public func warn(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        clientBehavior.warn(message(), file: file, function: function, line: line)
    }

    public func info(_ message: @autoclosure () -> String,
                     file: String = #file,
                     function: String = #function,
                     line: Int = #line) {
        clientBehavior.info(message(), file: file, function: function, line: line)
    }

    public func debug(_ message: @autoclosure () -> String,
                      file: String = #file,
                      function: String = #function,
                      line: Int = #line) {
        clientBehavior.debug(message(), file: file, function: function, line: line)
    }

    public func verbose(_ message: @autoclosure () -> String,
                        file: String = #file,
                        function: String = #function,
                        line: Int = #line) {
        clientBehavior.verbose(message(), file: file, function: function, line: line)
    }

}
