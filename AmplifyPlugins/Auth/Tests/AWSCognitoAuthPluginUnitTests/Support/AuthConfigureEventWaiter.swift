//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin

/// Lets a test that calls `Amplify.configure` wait for the Auth plugin to finish configuring before it
/// resets Amplify.
///
/// A successful `Amplify.configure` returns while the plugin's `AuthConfigureOperation` is still running,
/// and that operation dispatches `InternalConfigureAuth` to Hub when it completes. If `Amplify.reset()`
/// runs first, that dispatch reaches an unconfigured Hub and traps ("Hub category is not configured").
/// Create the waiter before configuring, since Hub accepts listeners then, so the event cannot be missed.
///
/// The event alone does not mean the dispatch is over: `HubCategory.dispatch` sends to the Combine
/// publishers first, synchronously, and only then asks the category for its plugin, which is where it
/// traps. So once the event has arrived, the waiter also waits for the configure operation to finish
/// (`AuthConfigureOperationSettler`), which it does only after its dispatch has returned.
final class AuthConfigureEventWaiter {

    private let dispatched = XCTestExpectation(description: "InternalConfigureAuth dispatched")
    private var subscription: AnyCancellable?

    init() {
        dispatched.assertForOverFulfill = false
        let dispatched = dispatched
        self.subscription = Amplify.Hub.publisher(for: .auth).sink { payload in
            if payload.eventName == "InternalConfigureAuth" {
                dispatched.fulfill()
            }
        }
    }

    /// Waits for the configure operation's Hub event, if the Auth category was configured and so started
    /// one, and then for the operation to finish; then stops listening. Call before `Amplify.reset()`.
    func waitIfConfigureStarted(timeout: TimeInterval = 10) async {
        if Amplify.Auth.isConfigured {
            _ = await XCTWaiter.fulfillment(of: [dispatched], timeout: timeout)
            let plugin = try? Amplify.Auth.getPlugin(for: "awsCognitoAuthPlugin") as? AWSCognitoAuthPlugin
            await plugin?.waitForConfigureOperation()
        }
        subscription?.cancel()
        subscription = nil
    }
}
