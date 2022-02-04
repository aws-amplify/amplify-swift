//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum FetchUserPoolTokensState: State {

    case configuring

    case refreshing

    case fetched

    case error(AuthorizationError)

}

public extension FetchUserPoolTokensState {
    var type: String {
        switch self {
        case .configuring: return "FetchUserPoolTokensState.configuring"
        case .refreshing: return "FetchUserPoolTokensState.refreshing"
        case .fetched: return "FetchUserPoolTokensState.fetched"
        case .error: return "FetchUserPoolTokensState.error"
        }
    }
}
