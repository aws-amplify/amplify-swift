//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyFoundation
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// Instance routing of the engine's log sites: sites with an environment log through that
/// environment's logger, whatever the initialization order. The static sites are covered, site by site,
/// by `EngineStaticLogSiteTests`.
class EngineLogSiteRoutingTests: XCTestCase {

    private var previousRouter: (any EngineLogRouter)?

    override func setUp() {
        super.setUp()
        previousRouter = EngineLog.router
    }

    override func tearDown() {
        if let previousRouter {
            EngineLog.install(previousRouter)
        }
        super.tearDown()
    }

    /// Test that two environments with different loggers route independently of initialization order
    ///
    /// - Given: A global router that records, and two environments, A and B, each with its own logger
    /// - When:
    ///    - The environments and a plugin are created in one order, then in the reverse order
    ///    - An action (shape C, `environment.logger`) and `FetchAuthSessionOperationHelper` (a scoped
    ///      site) log with B, then with A
    /// - Then:
    ///    - In both orders, each environment's logger receives exactly its own lines, at the plugin's
    ///      scope and at the helper's literal scope
    ///    - The global router receives none of them
    ///
    func testTwoEnvironmentsRouteIndependentlyOfInitializationOrder() async {
        for reversed in [false, true] {
            let global = CapturingRouter()
            EngineLog.install(global)
            let loggerA = CapturingRouter()
            let loggerB = CapturingRouter()

            var environments: [String: AuthEnvironment] = [:]
            let order = reversed ? ["B", "A", "plugin"] : ["plugin", "A", "B"]
            for name in order {
                switch name {
                case "A": environments["A"] = Self.environment(logger: loggerA)
                case "B": environments["B"] = Self.environment(logger: loggerB)
                default: _ = AWSCognitoAuthPlugin()
                }
            }

            for name in ["B", "A"] {
                let environment = environments[name]!
                await InitializeFetchUnAuthSession().execute(
                    withDispatcher: MockDispatcher { _ in },
                    environment: environment
                )
                let helper = FetchAuthSessionOperationHelper()
                helper.environment = environment
                helper.log.verbose("helper line from \(name)")
            }

            for (name, logger) in [("A", loggerA), ("B", loggerB)] {
                let context = "environment \(name), reversed: \(reversed)"
                XCTAssertEqual(
                    logger.entries.count(where: { $0.scope == AmplifyEngineLogRouter.pluginScope }), 2, context
                )
                XCTAssertEqual(
                    logger.entries.filter { $0.scope == .category("FetchAuthSessionOperationHelper") }.map(\.message),
                    ["helper line from \(name)"],
                    context
                )
                XCTAssertEqual(logger.entries.count, 3, context)
            }
            XCTAssertTrue(global.entries.isEmpty, "reversed: \(reversed)")
        }
    }

    /// Test that a missing device record logs one line that prints nothing of the environment
    ///
    /// - Given: An environment whose credential store has no device metadata, and whose user pool
    ///   configuration has an app client secret
    /// - When:
    ///    - `DeviceMetadataHelper.getDeviceMetadata` reads a user's device metadata
    /// - Then:
    ///    - It returns `.noData`, and logs exactly "No existing device metadata found." at info: the
    ///      environment, and the part of the client secret its description holds, is not printed
    ///
    func testAMissingDeviceRecordLogsNothingOfTheEnvironment() async {
        let logger = CapturingRouter()
        let environment = Self.environment(logger: logger, credentialsClient: NoDeviceMetadataStore())

        let metadata = await DeviceMetadataHelper.getDeviceMetadata(for: "alice", with: environment)

        XCTAssertEqual(metadata, .noData)
        XCTAssertEqual(logger.entries.map(\.message), ["No existing device metadata found."])
        XCTAssertEqual(logger.entries.map(\.level), [.info])
    }

    private static func environment(
        logger: CapturingRouter,
        credentialsClient: (any CredentialStoreStateBehavior)? = nil
    ) -> AuthEnvironment {
        let base = Defaults.makeDefaultAuthEnvironment()
        return AuthEnvironment(
            configuration: base.configuration,
            userPoolConfigData: base.userPoolConfigData,
            identityPoolConfigData: base.identityPoolConfigData,
            authenticationEnvironment: base.authenticationEnvironment,
            authorizationEnvironment: base.authorizationEnvironment,
            credentialsClient: credentialsClient ?? base.credentialsClient,
            logger: CapturingScopedLogger(scope: AmplifyEngineLogRouter.pluginScope, router: logger)
        )
    }
}

/// A credential store with no device metadata for anyone.
private struct NoDeviceMetadataStore: CredentialStoreStateBehavior {
    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        throw EngineCredentialStoreError.itemNotFound
    }

    func storeData(data: CredentialStoreData) async throws {}

    func deleteData(type: CredentialStoreDataType) async throws {}
}

/// An `EngineScopedLogger` that records into a `CapturingRouter`, so each environment has its own sink.
private struct CapturingScopedLogger: EngineScopedLogger {
    let scope: EngineLogScope
    let router: CapturingRouter

    func scoped(_ scope: EngineLogScope) -> EngineLogger {
        router.logger(scope)
    }

    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).error(message(), error())
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).warn(message(), error())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).info(message(), error())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).debug(message(), error())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).verbose(message(), error())
    }

    func log(_ logLevel: AmplifyFoundation.LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        router.logger(scope).log(logLevel, message(), error())
    }
}
