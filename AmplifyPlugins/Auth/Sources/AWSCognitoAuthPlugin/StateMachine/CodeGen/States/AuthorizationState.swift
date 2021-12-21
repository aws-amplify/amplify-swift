//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift

public enum AuthorizationState: State {
    case unconfigured
}


public extension AuthorizationState {
    var type: String {
        switch self {
        case .unconfigured: return "AuthorizationState.unconfigured"
        }
    }
}
