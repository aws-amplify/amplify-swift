//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin

/// Waits for a plugin's configure operation to dispatch `InternalConfigureAuth`.
///
/// `configure` starts an `AuthConfigureOperation` on the plugin's queue. The operation waits, on a task of
/// its own, for the state machine to be `.configured`, then dispatches `InternalConfigureAuth` to
/// `Amplify.Hub`. Nothing in a test awaits that task, so under load it can run after the test has ended. If
/// it runs while a test is inside `Amplify.reset()`, after the Hub category was reset and before it is
/// replaced, `HubCategory.plugin` traps: "Hub category is not configured".
///
/// The operation dispatches before it finishes, so a barrier on its queue runs after the dispatch. The
/// settler keeps the queue and the state machine, and keeps the plugin only if it must wait for the
/// configuration to finish: a released plugin's configuration can fail (its client factories throw), and
/// then the operation never dispatches.
struct AuthConfigureOperationSettler: Sendable {

    private let queue: OperationQueue?
    private let authStateMachine: AuthStateMachine?
    private let awaitingConfiguration: Bool
    private let plugin: AWSCognitoAuthPlugin?

    init(_ plugin: AWSCognitoAuthPlugin, awaitingConfiguration: Bool = false) {
        self.queue = plugin.queue
        self.authStateMachine = plugin.authStateMachine
        self.awaitingConfiguration = awaitingConfiguration
        self.plugin = awaitingConfiguration ? plugin : nil
    }

    /// Returns once the configure operation has dispatched its result.
    ///
    /// The operation finishes only after it has seen `.configured`. By default a machine that is not
    /// `.configured` now is not waited for: it was never configured, or it was given a state that does
    /// not configure. With `awaitingConfiguration`, for a configuration that is still running and must
    /// succeed (`configure(using:)` with a valid configuration), the settler first waits for
    /// `.configured`, and fails the test if the machine is not configured within `timeout`. The wait for
    /// the operation itself is bounded by `timeout` too, and fails the test if it runs out.
    func wait(
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        guard let queue, let authStateMachine else {
            return
        }
        if awaitingConfiguration {
            guard await Self.configured(authStateMachine, within: timeout) else {
                XCTFail("The plugin's configuration did not finish within \(timeout) seconds", file: file, line: line)
                return
            }
        } else {
            guard case .configured = await authStateMachine.currentState else {
                return
            }
        }
        // Bounded, so an operation that never finishes fails the test instead of hanging the run.
        let barrierRan = XCTestExpectation(description: "Barrier after the configure operation ran")
        queue.addBarrierBlock {
            barrierRan.fulfill()
        }
        let result = await XCTWaiter.fulfillment(of: [barrierRan], timeout: timeout)
        if result != .completed {
            XCTFail("The plugin's configure operation did not finish within \(timeout) seconds", file: file, line: line)
        }
    }

    /// Whether `machine` reaches `.configured` within `timeout`. The timeout only bounds a configuration
    /// that never finishes; it does not decide anything that finishes.
    private static func configured(_ machine: AuthStateMachine, within timeout: TimeInterval) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                // The stream must outlive the loop: releasing it cancels its subscription, and the loop
                // then waits forever after the states already buffered.
                let states = await machine.listen()
                defer { withExtendedLifetime(states) {} }
                for await state in states {
                    if case .configured = state {
                        return true
                    }
                }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
    }
}

extension AWSCognitoAuthPlugin {

    /// See `AuthConfigureOperationSettler.wait()`.
    func waitForConfigureOperation() async {
        await AuthConfigureOperationSettler(self).wait()
    }
}

extension XCTestCase {

    /// Registers a teardown block that waits for `plugin`'s configure operation to dispatch its result
    /// (`AuthConfigureOperationSettler`), so the dispatch cannot outlive the test. Teardown blocks run
    /// before `tearDown()`, and so before any `Amplify.reset()` there.
    func settleConfigureOperationOnTeardown(
        of plugin: AWSCognitoAuthPlugin,
        awaitingConfiguration: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let settler = AuthConfigureOperationSettler(plugin, awaitingConfiguration: awaitingConfiguration)
        addTeardownBlock {
            await settler.wait(file: file, line: line)
        }
    }
}
