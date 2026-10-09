//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`. XCTest runs one test at a time.
final class AuthConfigureOperationTests: XCTestCase, @unchecked Sendable {

    private var savedHubPlugins: [PluginKey: HubCategoryPlugin] = [:]

    override func setUp() {
        savedHubPlugins = Amplify.Hub.plugins
    }

    override func tearDown() {
        Amplify.Hub.plugins = savedHubPlugins
    }

    /// Test that the configure operation has dispatched its result by the time it finishes
    ///
    /// - Given: A plugin configured on a suspended queue, and a Hub plugin that records, when
    ///   `InternalConfigureAuth` is dispatched, whether the configure operation had already finished
    /// - When:
    ///    - The queue runs the configure operation and a barrier queued after it
    /// - Then:
    ///    - The operation's `InternalConfigureAuth` was dispatched once, before it finished, so the barrier
    ///      runs after the dispatch
    ///
    func testConfigureOperationDispatchesItsResultBeforeFinishing() async throws {
        let queue = OperationQueue()
        queue.isSuspended = true
        let plugin = AWSCognitoAuthPlugin()
        plugin.configure(
            authConfiguration: Defaults.makeDefaultAuthConfigData(),
            authEnvironment: Defaults.makeDefaultAuthEnvironment(),
            authStateMachine: Defaults.makeDefaultAuthStateMachine(
                initialState: .configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
            ),
            credentialStoreStateMachine: Defaults.makeDefaultCredentialStateMachine(),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler(),
            queue: queue
        )
        let operation = try XCTUnwrap(queue.operations.first as? AuthConfigureOperation)
        // Only this operation's result: another plugin's configure operation, still running from an earlier
        // test, dispatches the same event name.
        let operationID = operation.id
        let recorder = DispatchRecordingHubPlugin { payload in
            guard payload.eventName == "InternalConfigureAuth",
                  (payload.context as? AmplifyOperationContext<AuthConfigureRequest>)?.operationId == operationID
            else {
                return nil
            }
            return operation.isFinished
        }
        Amplify.Hub.plugins = [recorder.key: recorder]

        queue.isSuspended = false
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.addBarrierBlock {
                continuation.resume()
            }
        }

        XCTAssertEqual(
            recorder.recorded,
            [false],
            "InternalConfigureAuth must be dispatched once, before the configure operation finishes"
        )
    }
}

/// Records, for each dispatch that `record` maps to a value, that value, at the moment of the dispatch.
private final class DispatchRecordingHubPlugin: HubCategoryPlugin, @unchecked Sendable {

    let key = "DispatchRecordingHubPlugin"
    private let record: (HubPayload) -> Bool?
    private let lock = NSLock()
    private var values: [Bool] = []

    init(record: @escaping (HubPayload) -> Bool?) {
        self.record = record
    }

    var recorded: [Bool] {
        lock.lock()
        defer { lock.unlock() }
        return values
    }

    func dispatch(to channel: HubChannel, payload: HubPayload) {
        guard let value = record(payload) else {
            return
        }
        lock.lock()
        values.append(value)
        lock.unlock()
    }

    func listen(to channel: HubChannel, eventName: HubPayloadEventName, listener: @escaping HubListener) -> UnsubscribeToken {
        UnsubscribeToken(channel: channel, id: UUID())
    }

    func listen(to channel: HubChannel, isIncluded filter: HubFilter?, listener: @escaping HubListener) -> UnsubscribeToken {
        UnsubscribeToken(channel: channel, id: UUID())
    }

    func removeListener(_ token: UnsubscribeToken) {}

    func configure(using configuration: Any?) throws {}

    func reset() async {}
}
