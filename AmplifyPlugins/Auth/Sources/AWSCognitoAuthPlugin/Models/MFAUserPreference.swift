//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Output for fetching MFA preference
public struct UserMFAPreference {

    /// nil if none enabled
    let enabled: Set<MFAType>?

    /// nil if no preference
    let preferred: MFAType?

    internal init(enabled: Set<MFAType>?, preferred: MFAType?) {
        self.enabled = enabled
        self.preferred = preferred
    }

}
