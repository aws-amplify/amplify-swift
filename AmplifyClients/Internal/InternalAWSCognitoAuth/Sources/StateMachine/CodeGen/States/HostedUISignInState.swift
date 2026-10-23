//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

package enum HostedUISignInState: State {
    case notStarted
    case showingUI(HostedUISigningInState)
    case fetchingToken
    case done
    case error(SignInError)
}

package extension HostedUISignInState {

    var type: String {
        switch self {
        case .notStarted: return "HostedUISignInState.notStarted"
        case .showingUI: return "HostedUISignInState.showingUI"
        case .fetchingToken: return "HostedUISignInState.fetchingToken"
        case .done: return "HostedUISignInState.done"
        case .error: return "HostedUISignInState.error"
        }
    }
}

package struct HostedUISigningInState: Equatable {

    package let signInURL: URL

    package let state: String

    package let codeChallenge: String

    package let presentationAnchor: EnginePresentationAnchor?

    package let options: HostedUIOptions

    package init(
        signInURL: URL,
        state: String,
        codeChallenge: String,
        presentationAnchor: EnginePresentationAnchor?,
        options: HostedUIOptions
    ) {
        self.signInURL = signInURL
        self.state = state
        self.codeChallenge = codeChallenge
        self.presentationAnchor = presentationAnchor
        self.options = options
    }
}
