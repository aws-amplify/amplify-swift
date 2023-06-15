//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Input for updating the MFA preference for a MFA Type
public enum MFAPreference {
    
    // enabled: false
    case disabled

    // enabled: true
    case enabled

    // enabled: true, preferred: true
    case preferred

    // enabled: true, preferred: false
    case notPreferred

}
