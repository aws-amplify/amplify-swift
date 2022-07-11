//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum SignInState: State {
    case notStarted
    case signingInWithSRP(SRPSignInState, SignInEventData)
    case signingInWithSRPCustom(SRPSignInState, SignInEventData)
    case signingInWithCustom(CustomSignInState, SignInEventData)
    case resolvingMFAChallenge
    case resolvingSMSChallenge(SignInChallengeState)
    case resolvingCustomChallenge(SignInChallengeState)
    case done
    case error
}

extension SignInState {

    var type: String {
        switch self {
        case .notStarted: return "SignInState.notStarted"
        case .signingInWithSRP: return "SignInState.signingInWithSRP"
        case .signingInWithSRPCustom: return "SignInState.signingInWithSRPCustom"
        case .signingInWithCustom: return "SignInState.signingInWithCustom"
        case .resolvingMFAChallenge: return "SignInState.resolvingMFAChallenge"
        case .resolvingSMSChallenge: return "SignInState.resolvingSMSChallenge"
        case .resolvingCustomChallenge:  return "SignInState.resolvingCustomChallenge"
        case .done: return "SignInState.done"
        case .error: return "SignInState.error"
        }
    }
}
