//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

// The engine's logging seam.
//
// Engine code logs through `AmplifyFoundation.Logger`, never through `Amplify.Logging`. Every site logs
// through its caller's `EngineScopedLogger`: the environment's where one is in scope, and otherwise one
// the caller passes in (value parsers such as `EngineMFAType(rawValue:logger:)`, the keychain store, the
// credential store, the WebAuthn delegate, the resolvers). So routing is decided per instance, and a
// standalone client's lines never take a plugin's categories. One site still goes through the
// process-global router: the public `AuthFlowType` decode (`EngineAuthFactorType(decodingRawValue:)`),
// which has no caller to ask. See `EngineLog`.
//
// Every site names its scope with a literal (`.categoryNamespace("Authentication", "InitiateAuthSRP")`,
// `.category("AuthFactorType")`), never with `String(describing: self)`, so that renaming a type does
// not change where its lines are logged.

/// The logger type engine code holds.
///
/// Engine files that are still inside the plugin module name Foundation's logger through this
/// alias, so they never need `import AmplifyFoundation` next to `import Amplify`, which declares a
/// `Logger` of its own.
package typealias EngineLogger = any AmplifyFoundation.Logger

/// Where a log line goes. Each case mirrors one of the ways the plugin resolves an `Amplify.Logging`
/// logger today.
package enum EngineLogScope: Hashable, Sendable {

    /// `Amplify.Logging.logger(forCategory:)`. This is what `DefaultLogger`'s default `log` does,
    /// with the type's name as the category.
    case category(String)

    /// `Amplify.Logging.logger(forCategory:forNamespace:)`, for example `("Authentication", "InitiateAuthSRP")`.
    case categoryNamespace(String, String)

    /// `Amplify.Logging.logger(forNamespace:)`, for example `"KeychainStore"`.
    case namespace(String)
}

/// A logger that can hand out loggers for other scopes.
///
/// Its own `Logger` methods log at the scope it was created with. For the plugin that is
/// `("Authentication", "AWSCognitoAuthPlugin")`, the scope of the plugin's `log`.
package protocol EngineScopedLogger: AmplifyFoundation.Logger {

    /// Returns a logger for `scope`, routed the same way as the receiver.
    func scoped(_ scope: EngineLogScope) -> EngineLogger
}

/// Resolves a scope to a logger. The plugin installs one that forwards to `Amplify.Logging`.
package protocol EngineLogRouter: Sendable {

    /// Returns the logger for `scope`. Called once per message, so an implementation must not
    /// cache anything that a later configuration could change.
    func logger(_ scope: EngineLogScope) -> EngineLogger
}

/// Entry point for the one engine log site that has no caller's logger: the public `AuthFlowType` decode.
///
/// **Ordering rule for the process-global router (static sites only).** A host installs its router
/// with `installIfDefault(_:)`, which only replaces the default `FoundationEngineLogRouter`, so the
/// first host to install wins and later installs are no-ops. `AWSCognitoAuthPlugin.init` is the only
/// production caller; the engine and the standalone client never install one. So:
/// - a static line logged before the first `AWSCognitoAuthPlugin.init` of the process goes to
///   `AmplifyFoundation`'s default router (no sinks unless the app added one);
/// - a static line logged after it goes to `Amplify.Logging`, however many plugins or clients were
///   created before or after, and in whatever order.
///
/// One static path is public and can run before any plugin exists: decoding the public `AuthFlowType`
/// (`AuthFlowType.init(from:)` → `AuthFactorType(rawValue:)`), for example from an app's own persisted
/// options. Its "unsupported factor" lines then go to `AmplifyFoundation`'s default router, not to
/// `Amplify.Logging` as before the engine had its own logging seam. This is accepted.
///
/// Sites with an environment in scope never read the global router: they log through their
/// environment's `EngineScopedLogger`, so their routing does not depend on initialization order at all.
/// `install(_:)` replaces the router unconditionally and exists for tests.
///
/// - Note: "The default is still in place" is a type check (`is FoundationEngineLogRouter`). Today every
///   installer is an `AWSCognitoAuthPlugin`, and each installs an identical, stateless router. If a second
///   production host adds its own router, whichever installs second is silently ignored, not
///   the last writer.
package enum EngineLog {

    /// Returns a logger for `scope`.
    ///
    /// The returned logger resolves the installed router on every message, not when it is created,
    /// so a router installed later still receives the messages of a logger obtained earlier.
    package static func logger(_ scope: EngineLogScope) -> EngineLogger {
        RoutedEngineLogger(scope: scope)
    }

    /// Replaces the process-global router unconditionally. For tests; hosts use `installIfDefault(_:)`.
    package static func install(_ router: any EngineLogRouter) {
        routerBox.set(router)
    }

    /// Installs `router` only if the default `FoundationEngineLogRouter` is still in place, and
    /// reports whether it did. The check and the install are one atomic step.
    @discardableResult
    package static func installIfDefault(_ router: any EngineLogRouter) -> Bool {
        routerBox.setIfDefault(router)
    }

    /// Restores the default router, which logs through `AmplifyLogging`.
    package static func resetRouter() {
        routerBox.set(FoundationEngineLogRouter())
    }

    /// The router currently installed.
    package static var router: any EngineLogRouter {
        routerBox.get()
    }

    private static let routerBox = EngineLogRouterBox(FoundationEngineLogRouter())
}

/// The default router: `AmplifyFoundation`'s own logging, which has no sinks unless the app added one.
///
/// `.category(c)` logs under `c`, and `.categoryNamespace(_, n)` and `.namespace(n)` under `n`. The
/// namespace is the type name, which matches how the standalone clients name their loggers
/// (`AmplifyLogging.logger(for: Type.self)`).
package struct FoundationEngineLogRouter: EngineLogRouter {

    package init() {}

    package func logger(_ scope: EngineLogScope) -> EngineLogger {
        AmplifyLogging.logger(for: Self.name(for: scope))
    }

    package static func name(for scope: EngineLogScope) -> String {
        switch scope {
        case .category(let category):
            return category
        case .categoryNamespace(_, let namespace):
            return namespace
        case .namespace(let namespace):
            return namespace
        }
    }
}

package extension CodingUserInfoKey {

    /// The caller's `EngineScopedLogger`, for a decode that logs: set it on the decoder's `userInfo`, and the
    /// engine's `Decodable` types log through it. Without it they log through the global router, as the
    /// plugin's public decode always has.
    static let engineLogger = CodingUserInfoKey(rawValue: "com.amplify.engineLogger")!
}

/// A logger that logs nothing, at every scope.
///
/// What a site gets when its environment carries no logger (an environment that is not a `LoggerProvider`,
/// where `logVerbose` and the other `Action` helpers log nothing either). Production environments always
/// carry a logger.
package struct DiscardingEngineLogger: EngineScopedLogger {

    package init() {}

    package func scoped(_ scope: EngineLogScope) -> EngineLogger {
        self
    }

    package func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}

    package func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}

    package func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}

    package func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}

    package func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}

    package func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {}
}

/// A logger for a fixed scope that asks `EngineLog.router` for the real logger on every message.
struct RoutedEngineLogger: AmplifyFoundation.Logger {

    let scope: EngineLogScope

    private var resolved: EngineLogger {
        EngineLog.router.logger(scope)
    }

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.error(message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.warn(message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.info(message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.debug(message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.verbose(message(), error())
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        resolved.log(logLevel, message(), error())
    }
}

/// Lock-protected storage for the global router.
///
/// - Note: `@unchecked Sendable` because every access to `router` goes through `lock`.
private final class EngineLogRouterBox: @unchecked Sendable {
    private let lock = NSLock()
    private var router: any EngineLogRouter

    init(_ router: any EngineLogRouter) {
        self.router = router
    }

    func get() -> any EngineLogRouter {
        lock.lock()
        defer { lock.unlock() }
        return router
    }

    func set(_ newValue: any EngineLogRouter) {
        lock.lock()
        defer { lock.unlock() }
        router = newValue
    }

    func setIfDefault(_ newValue: any EngineLogRouter) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard router is FoundationEngineLogRouter else {
            return false
        }
        router = newValue
        return true
    }
}
