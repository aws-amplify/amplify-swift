//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSCognitoAuthPlugin {

    func listenToStateMachineChanges() {


        Task {
            let stateSequences = await authStateMachine.listen()
            for await state in stateSequences {
                self.log.verbose("""
                Auth state change:

                \(state)

                """)
            }
        }
        Task {
            let stateSequences = await credentialStoreStateMachine.listen()
            for await state in stateSequences {
                self.log.verbose("""
                Credential Store state change:

                \(state)

                """)
            }
        }
    }
}
