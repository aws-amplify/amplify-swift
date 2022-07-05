//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum HostedUISignInState: State {
    case notStarted
    case showingUI(HostedUISignInData)
    case fetchingToken
    case done
    case error
}

extension HostedUISignInState {

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


struct HostedUISignInData: Equatable {

    let signInURL: URL

    let state: String

    let codeChallenge: String
}
