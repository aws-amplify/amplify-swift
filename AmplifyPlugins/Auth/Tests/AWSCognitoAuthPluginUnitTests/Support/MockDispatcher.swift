//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import hierarchical_state_machine_swift

struct MockDispatcher: EventDispatcher {
    typealias SendCallback = (StateMachineEvent) -> Void
    let sendCallback: SendCallback

    init(_ sendCallback: @escaping SendCallback) {
        self.sendCallback = sendCallback
    }

    func send(_ event: StateMachineEvent) {
        sendCallback(event)
    }
}
