//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum FetchAWSCredentialsState: State {

    case configuring

    case refreshing

    case fetching

    case fetched

    case error

}

public extension FetchAWSCredentialsState {
    var type: String {
        switch self {
        case .configuring: return "FetchAWSCredentialsState.configuring"
        case .refreshing: return "FetchAWSCredentialsState.refreshing"
        case .fetching: return "FetchAWSCredentialsState.fetching"
        case .fetched: return "FetchAWSCredentialsState.fetched"
        case .error: return "FetchAWSCredentialsState.error"
        }
    }
}

