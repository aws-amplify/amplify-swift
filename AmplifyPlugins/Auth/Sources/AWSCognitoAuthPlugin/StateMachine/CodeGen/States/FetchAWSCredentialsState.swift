//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum FetchAWSCredentialsState: State {

    case configuring

    case fetching

    case fetched

    case error(AuthorizationError)

}

extension FetchAWSCredentialsState {
    var type: String {
        switch self {
        case .configuring: return "FetchAWSCredentialsState.configuring"
        case .fetching: return "FetchAWSCredentialsState.fetching"
        case .fetched: return "FetchAWSCredentialsState.fetched"
        case .error: return "FetchAWSCredentialsState.error"
        }
    }
}
