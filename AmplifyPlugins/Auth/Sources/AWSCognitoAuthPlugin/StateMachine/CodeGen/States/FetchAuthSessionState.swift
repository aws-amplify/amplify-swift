//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum FetchAuthSessionState: State {
    
    case determiningUserState
    
    case fetchingUserPoolTokens(FetchUserPoolTokensState)
    
    case fetchingIdentity(FetchIdentityState)
    
    case fetchingAWSCredentials(FetchAWSCredentialsState)
    
    case sessionEstablished
    
    case error

}

public extension FetchAuthSessionState {
    var type: String {
        switch self {
        case .determiningUserState: return "FetchAuthSessionState.determiningUserState"
        case .fetchingUserPoolTokens: return "FetchAuthSessionState.fetchingUserPoolTokens"
        case .fetchingIdentity: return "FetchAuthSessionState.fetchingIdentity"
        case .fetchingAWSCredentials: return "FetchAuthSessionState.fetchingAwsCredentials"
        case .sessionEstablished: return "FetchAuthSessionState.sessionEstablished"
        case .error: return "FetchAuthSessionState.error"
        }
    }
}
    
