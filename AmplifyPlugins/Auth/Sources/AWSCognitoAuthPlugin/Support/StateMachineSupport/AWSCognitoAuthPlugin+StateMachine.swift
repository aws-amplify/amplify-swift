//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AWSCognitoAuthPlugin {

    func listenToStateMachineChanges() {

        self.authStateListenerToken = authStateMachine.listen { state in
            self.log.verbose("""
            Auth state change:

            \(state)

            """)

        } onSubscribe: { }

        self.credentialStoreStateListenerToken = credentialStoreStateMachine.listen { state in
            self.log.verbose("""
            Credential Store state change:

            \(state)

            """)

        } onSubscribe: { }

    }
}
