//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import InternalAWSCognitoAuth

typealias AuthStateMachine = StateMachine<
    AuthState,
    AuthEnvironment
>
// `CredentialStoreStateMachine` is declared with `CredentialStoreOperationClient`, which moves into the engine.
