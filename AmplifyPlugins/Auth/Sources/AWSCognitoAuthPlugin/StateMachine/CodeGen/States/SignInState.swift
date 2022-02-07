//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInState: State {
    case signingInWithSRP(SRPSignInState, SignInEventData)
    case signingInWithSocial
    case signingInWithCustom
    case resolvingMFAChallenge
}

extension SignInState {
    
    var type: String {
        switch self {
        case .signingInWithSRP: return "SignInState.signingInWithSRP"
        case .signingInWithSocial: return "SignInState.signingInWithSocial"
        case .signingInWithCustom: return "SignInState.signingInWithCustom"
        case .resolvingMFAChallenge: return "SignInState.resolvingMFAChallenge"
        }
    }
}
