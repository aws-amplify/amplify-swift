//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

import ClientRuntime
import AWSCognitoIdentityProvider

typealias ConfigureOperation = AmplifyOperation<
    AuthConfigureRequest,
    Void,
    AuthError>

class AuthConfigureOperation: ConfigureOperation {

    let authConfiguration: AuthConfiguration
    let authStateMachine: AuthStateMachine
    let credentialStoreStateMachine: CredentialStoreStateMachine

    init(request: AuthConfigureRequest,
         authStateMachine: AuthStateMachine,
         credentialStoreStateMachine: CredentialStoreStateMachine) {

        self.authConfiguration = request.authConfiguration
        self.authStateMachine = authStateMachine
        self.credentialStoreStateMachine = credentialStoreStateMachine
        super.init(categoryType: .auth,
                   eventName: "InternalConfigureAuth",
                   request: request)
    }


    override public func main() {
        if isCancelled {
            finish()
            return
        }

        sendConfigureAuthEvent()
    }

    func sendConfigureAuthEvent() {
        Task {
            let event = AuthEvent(eventType: .configureAuth(self.authConfiguration))
            await self.authStateMachine.send(event)
            let stateSequences = await authStateMachine.listen()
            for await state in stateSequences {
                if case .configured = state {
                    finish()
                    break
                }
            }
        }

    }
}

struct AuthConfigureRequest: AmplifyOperationRequest {

    let authConfiguration: AuthConfiguration

    var options: Options

    init(authConfiguration: AuthConfiguration, options: Options = Options()) {
        self.authConfiguration = authConfiguration
        self.options = options
    }
}

extension AuthConfigureRequest {

    struct Options {}
}
