//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
/// A configured plugin must be released once nothing holds it, and a released plugin's Hub listener
/// must not keep answering the Hub. Before this was fixed, the environment's factory closures and the
/// state-machine logging tasks held the plugin, so every plugin configured in a process stayed alive,
/// and one sign-in arrived as one `signedIn` event per plugin ever configured.
class AWSCognitoAuthPluginLifetimeTests: XCTestCase, @unchecked Sendable {

    private static let pluginConfiguration: JSONValue = [
        "CredentialsProvider": [
            "CognitoIdentity": [
                "Default": [
                    "PoolId": "us-east-1:lifetime-tests",
                    "Region": "us-east-1"
                ]
            ]
        ],
        "CognitoUserPool": [
            "Default": [
                "PoolId": "us-east-1_lifetime",
                "Region": "us-east-1",
                "AppClientId": "lifetimeTestsClient"
            ]
        ]
    ]

    override func tearDown() async throws {
        await Amplify.reset()
    }

    /// A plugin configured outside Amplify is released when the last reference goes
    ///
    /// - Given: A plugin configured with `configure(using:)` and not added to Amplify
    /// - When:
    ///    - Its configuration finishes and the only reference to it is dropped
    /// - Then:
    ///    - The plugin is deallocated
    ///
    func testPluginIsReleasedAfterConfigure() async throws {
        weak var weakPlugin: AWSCognitoAuthPlugin?
        do {
            let plugin = AWSCognitoAuthPlugin()
            weakPlugin = plugin
            try await configureAndWait(plugin)
        }

        await waitForRelease { weakPlugin == nil }
        XCTAssertNil(weakPlugin, "The plugin is still alive after its last reference was dropped")
    }

    /// A plugin added to Amplify is released by `Amplify.reset()`
    ///
    /// - Given: A plugin added to Amplify and configured through `Amplify.configure`
    /// - When:
    ///    - `Amplify.reset()` runs and the test's own reference is dropped
    /// - Then:
    ///    - The plugin is deallocated
    ///
    func testPluginIsReleasedAfterAmplifyReset() async throws {
        weak var weakPlugin: AWSCognitoAuthPlugin?
        do {
            let plugin = AWSCognitoAuthPlugin()
            weakPlugin = plugin
            let configured = configureEventExpectation()
            try Amplify.add(plugin: plugin)
            try Amplify.configure(AmplifyConfiguration(auth: AuthCategoryConfiguration(plugins: [
                plugin.key: Self.pluginConfiguration
            ])))
            await fulfillment(of: [configured.expectation], timeout: 10)
            configured.subscription.cancel()
            await plugin.waitForConfigureOperation()
        }

        await Amplify.reset()

        await waitForRelease { weakPlugin == nil }
        XCTAssertNil(weakPlugin, "The plugin is still alive after Amplify.reset()")
    }

    /// A dropped plugin does not repeat Hub events
    ///
    /// - Given: A plugin configured with `configure(using:)`, then dropped, and a live Hub event handler
    /// - When:
    ///    - A successful sign-in result is dispatched on the Hub
    /// - Then:
    ///    - Exactly one `signedIn` event is sent, by the live handler; the dropped plugin sends none
    ///
    func testDroppedPluginSendsNoDuplicateHubEvents() async throws {
        weak var weakPlugin: AWSCognitoAuthPlugin?
        do {
            let plugin = AWSCognitoAuthPlugin()
            weakPlugin = plugin
            try await configureAndWait(plugin)
        }
        await waitForRelease { weakPlugin == nil }

        let liveHandler = AuthHubEventHandler()
        let signedInCount = SignedInCounter()
        let firstSignedIn = expectation(description: "The live handler sends signedIn")
        let listenerToken = Amplify.Hub.listen(to: .auth, eventName: HubPayload.EventName.Auth.signedIn) { _ in
            if signedInCount.increment() == 1 {
                firstSignedIn.fulfill()
            }
        }
        defer { Amplify.Hub.removeListener(listenerToken) }

        let result: AWSAuthSignInTask.AmplifyAuthTaskResult = .success(AuthSignInResult(nextStep: .done))
        Amplify.Hub.dispatch(
            to: .auth,
            payload: HubPayload(eventName: HubPayload.EventName.Auth.signInAPI, data: result)
        )

        await fulfillment(of: [firstSignedIn], timeout: 5)
        // Drain the Hub. Its dispatcher runs one payload at a time, in order, and calls every listener of a
        // payload before the next one starts. Every handler answered `signInAPI` while that payload was
        // running, so each `signedIn` it sent was queued before the first one arrived here. A marker
        // dispatched now is therefore delivered after all of them.
        let drained = expectation(description: "The Hub delivered everything queued before the marker")
        let markerToken = Amplify.Hub.listen(to: .auth, eventName: "AWSCognitoAuthPluginLifetimeTests.drain") { _ in
            drained.fulfill()
        }
        defer { Amplify.Hub.removeListener(markerToken) }
        Amplify.Hub.dispatch(to: .auth, payload: HubPayload(eventName: "AWSCognitoAuthPluginLifetimeTests.drain"))
        await fulfillment(of: [drained], timeout: 5)
        XCTAssertEqual(signedInCount.value, 1, "One sign-in produced \(signedInCount.value) signedIn events")
        withExtendedLifetime(liveHandler) {}
    }

    /// The Hub event handler removes its Hub listener when it is released
    ///
    /// - Given: An `AuthHubEventHandler`, whose listener is registered on the default Hub plugin
    /// - When:
    ///    - The handler is released
    /// - Then:
    ///    - The Hub plugin no longer has the listener
    ///
    func testHubListenerIsRemovedWhenHandlerIsReleased() throws {
        let hubPlugin = try XCTUnwrap(Amplify.Hub.getPlugin(for: AWSHubPlugin.key) as? AWSHubPlugin)
        var handler: AuthHubEventHandler? = AuthHubEventHandler()
        let token = try XCTUnwrap(handler?.listenerToken)
        XCTAssertTrue(hubPlugin.hasListener(withToken: token))

        handler = nil

        XCTAssertNil(handler)
        XCTAssertFalse(hubPlugin.hasListener(withToken: token), "The released handler's listener is still registered")
    }

    /// Resetting the Hub does not deadlock when a Hub listener is the plugin's last owner
    ///
    /// - Given: A configured plugin whose only strong reference is held by a Hub listener closure
    /// - When:
    ///    - The Hub plugin is reset, which removes (and releases) every listener
    /// - Then:
    ///    - The reset finishes, and the plugin is released; its Hub handler's `deinit` removes its own
    ///      listener from the same Hub plugin while that reset is running
    ///
    func testHubResetDoesNotDeadlockWhenAListenerOwnsThePlugin() async throws {
        let hubPlugin = try XCTUnwrap(Amplify.Hub.getPlugin(for: AWSHubPlugin.key) as? AWSHubPlugin)
        weak var weakPlugin: AWSCognitoAuthPlugin?
        do {
            let plugin = AWSCognitoAuthPlugin()
            weakPlugin = plugin
            try await configureAndWait(plugin)
            _ = Amplify.Hub.listen(to: .storage) { _ in
                withExtendedLifetime(plugin) {}
            }
        }
        XCTAssertNotNil(weakPlugin, "The listener should be the plugin's owner")

        let resetFinished = expectation(description: "The Hub reset finished")
        Task.detached {
            await hubPlugin.reset()
            resetFinished.fulfill()
        }

        await fulfillment(of: [resetFinished], timeout: 5)
        await waitForRelease { weakPlugin == nil }
        XCTAssertNil(weakPlugin)
    }

    // MARK: - Helpers

    /// Configures `plugin` outside Amplify and waits until its configuration has finished, and its
    /// configure operation with it: the Hub event reaches the Combine publisher before the dispatch is over
    /// (`AuthConfigureEventWaiter`).
    private func configureAndWait(_ plugin: AWSCognitoAuthPlugin) async throws {
        let configured = configureEventExpectation()
        try plugin.configure(using: Self.pluginConfiguration)
        await fulfillment(of: [configured.expectation], timeout: 10)
        configured.subscription.cancel()
        await plugin.waitForConfigureOperation()
    }

    private func configureEventExpectation() -> (expectation: XCTestExpectation, subscription: AnyCancellable) {
        let configured = expectation(description: "InternalConfigureAuth dispatched")
        configured.assertForOverFulfill = false
        let subscription = Amplify.Hub.publisher(for: .auth).sink { payload in
            if payload.eventName == "InternalConfigureAuth" {
                configured.fulfill()
            }
        }
        return (configured, subscription)
    }

    /// Polls for up to five seconds: tasks that finish the configuration may hold the plugin briefly.
    private func waitForRelease(_ isReleased: () -> Bool) async {
        for _ in 0 ..< 250 where !isReleased() {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }
}

private final class SignedInCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() -> Int {
        lock.withLock {
            count += 1
            return count
        }
    }
}
