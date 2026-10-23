//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSCognitoAuthPlugin {

    func listenToStateMachineChanges() {

        // Neither task may hold the plugin: each runs until its state machine is released, and the
        // plugin owns the state machines. `self.log` is `Self.log`.
        Task { [weak self] in
            guard let stateSequences = await self?.authStateMachine.listen() else { return }
            for await state in stateSequences {
                Self.log.verbose("""
                Auth state change:

                \(state)

                """)
            }
        }
        Task { [weak self] in
            guard let stateSequences = await self?.credentialStoreStateMachine.listen() else { return }
            for await state in stateSequences {
                Self.log.verbose("""
                Credential Store state change:

                \(state)

                """)
            }
        }
    }
}
