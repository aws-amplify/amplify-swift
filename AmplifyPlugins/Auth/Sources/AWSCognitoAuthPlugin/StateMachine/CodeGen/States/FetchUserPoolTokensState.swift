//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum FetchUserPoolTokensState: State {
    
    case configuring
    
    case refreshing
    
    case fetching
    
    case fetched
    
    case error

}

public extension FetchUserPoolTokensState {
    var type: String {
        switch self {
        case .configuring: return "FetchUserPoolTokensState.configuring"
        case .refreshing: return "FetchUserPoolTokensState.refreshing"
        case .fetching: return "FetchUserPoolTokensState.fetching"
        case .fetched: return "FetchUserPoolTokensState.fetched"
        case .error: return "FetchUserPoolTokensState.error"
        }
    }
}
    
