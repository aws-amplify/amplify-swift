//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum FetchIdentityState: State {

    case configuring

    case fetching

    case fetched(String)

    case error(AuthorizationError)

}

extension FetchIdentityState {
    var type: String {
        switch self {
        case .configuring: return "FetchIdentityState.configuring"
        case .fetching: return "FetchIdentityState.fetching"
        case .fetched: return "FetchIdentityState.fetched"
        case .error: return "FetchIdentityState.error"
        }
    }
}
