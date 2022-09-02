//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSCognitoAuthPlugin

//class MockAuthStateMachine: StateMachine<AuthState, AuthEnvironment> {
//    let authState: AuthState
//
//    init (authState: AuthState) {
//        let resolver = AuthState.Resolver()
//        let environment = Defaults.makeDefaultAuthEnvironment()
//        self.authState = authState
//        super.init(resolver: resolver, environment: environment)
//    }
//
//    override func getCurrentState(_ completion: @escaping (AuthState) -> Void) {
//        completion(authState)
//    }
//
//    override var currentMachineState: AuthState {
//        get async {
//            authState
//        }
//    }
//}
