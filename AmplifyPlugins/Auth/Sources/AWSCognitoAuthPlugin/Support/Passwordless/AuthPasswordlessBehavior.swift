//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// Protocol for initiating sign up in a passwordless flow
protocol AuthPasswordlessBehavior {
    
    func preInitiateAuthSignUp(
        endpoint: URL,
        payload: PreInitiateAuthSignUpPayload) 
    async throws
    
}
