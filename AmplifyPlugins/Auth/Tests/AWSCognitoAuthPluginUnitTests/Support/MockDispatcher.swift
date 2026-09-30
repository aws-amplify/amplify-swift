//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin

struct MockDispatcher: EventDispatcher {
    // `@Sendable` because `EventDispatcher` is `Sendable` and dispatch happens from detached tasks.
    typealias SendCallback = @Sendable (StateMachineEvent) -> Void
    let sendCallback: SendCallback

    init(_ sendCallback: @escaping SendCallback) {
        self.sendCallback = sendCallback
    }

    func send(_ event: StateMachineEvent) {
        sendCallback(event)
    }
}
