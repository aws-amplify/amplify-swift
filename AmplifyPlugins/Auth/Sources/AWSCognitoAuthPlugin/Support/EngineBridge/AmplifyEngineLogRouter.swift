//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyFoundation
import InternalAWSCognitoAuth

/// Routes engine log lines to `Amplify.Logging`.
///
/// It is both the plugin's `EngineScopedLogger`, scoped to the plugin's own `log`
/// (`("Authentication", "AWSCognitoAuthPlugin")`), and the global `EngineLogRouter` for engine sites
/// with no environment. `AWSCognitoAuthPlugin.init` installs it as the global router.
///
/// The `Amplify.Logging` logger is resolved on every message and never cached, as
/// `AmplifyLoggerBridge` does, so a logging plugin added after `configure` still receives messages.
///
/// Kept in its own file because `Amplify` and `AmplifyFoundation` both declare `Logger` and
/// `LogLevel`; here they are always qualified.
struct AmplifyEngineLogRouter: EngineScopedLogger, EngineLogRouter {

    /// The scope of `AWSCognitoAuthPlugin.log`: `CategoryType.auth.displayName` and the plugin's type name.
    static let pluginScope = EngineLogScope.categoryNamespace("Authentication", "AWSCognitoAuthPlugin")

    let scope: EngineLogScope

    private let resolve: @Sendable (EngineLogScope) -> any AmplifyCategoryLogger

    init(scope: EngineLogScope = Self.pluginScope) {
        self.init(scope: scope, resolve: { Self.amplifyLogger(for: $0, in: Amplify.Logging) })
    }

    /// For tests: `resolve` stands in for `Amplify.Logging`.
    init(scope: EngineLogScope, resolve: @escaping @Sendable (EngineLogScope) -> any AmplifyCategoryLogger) {
        self.scope = scope
        self.resolve = resolve
    }

    /// The `Amplify.Logging` call each scope stands for. These are the calls the plugin's log sites
    /// make today.
    static func amplifyLogger(
        for scope: EngineLogScope,
        in logging: any LoggingCategoryClientBehavior
    ) -> any AmplifyCategoryLogger {
        switch scope {
        case .category(let category):
            return logging.logger(forCategory: category)
        case .categoryNamespace(let category, let namespace):
            return logging.logger(forCategory: category, forNamespace: namespace)
        case .namespace(let namespace):
            return logging.logger(forNamespace: namespace)
        }
    }

    // MARK: EngineScopedLogger

    func scoped(_ scope: EngineLogScope) -> EngineLogger {
        AmplifyEngineLogRouter(scope: scope, resolve: resolve)
    }

    // MARK: EngineLogRouter

    func logger(_ scope: EngineLogScope) -> EngineLogger {
        scoped(scope)
    }

    // MARK: AmplifyFoundation.Logger

    /// Forwards to Amplify's `error(error:)` when the message is empty and an error is passed: that
    /// is what the plugin's `log.error(error:)` sites become (`logger.error("", error)`). A message
    /// with an error is forwarded as one `error(_:)` line, `"<message> - <localizedDescription>"`,
    /// the format of `AmplifyFoundation`'s own sink, so the error is never dropped.
    ///
    /// Telling the two apart needs the message, so when an error is passed the message is built
    /// before Amplify's level check, at every level. The router does not consult `logLevel`: an
    /// Amplify `BroadcastLogger` reports only its first target's level, and targets such as CloudWatch
    /// filter by their own rules and record `error(error:)` differently from `error(_:)`. Error-level
    /// lines that carry an error are rare, so the eager message is cheap. Without an error, and at every
    /// other level, the message stays inside Amplify's autoclosure.
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        let logger = resolve(scope)
        guard let error = error() else {
            logger.error(message())
            return
        }
        let text = message()
        if text.isEmpty {
            logger.error(error: error)
        } else {
            logger.error(Self.render(text, error))
        }
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolve(scope).warn(Self.render(message(), error()))
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolve(scope).info(Self.render(message(), error()))
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolve(scope).debug(Self.render(message(), error()))
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolve(scope).verbose(Self.render(message(), error()))
    }

    /// The text of a line that carries an error, as `AmplifyFoundation`'s sink prints it. Without an
    /// error, the message unchanged. Only called from inside the autoclosures passed to Amplify, so
    /// it runs only when a target logs the line.
    static func render(_ message: String, _ error: Error?) -> String {
        guard let error else {
            return message
        }
        let description = error.localizedDescription
        return message.isEmpty ? description : "\(message) - \(description)"
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        switch logLevel {
        case .none:
            break
        case .error:
            self.error(message(), error())
        case .warn:
            warn(message(), error())
        case .info:
            info(message(), error())
        case .debug:
            debug(message(), error())
        case .verbose:
            verbose(message(), error())
        }
    }
}
