//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

/// Output for fetching MFA preference
public struct UserMFAPreference {

    /// nil if none enabled
    public let enabled: Set<MFAType>?

    /// nil if no preference
    public let preferred: MFAType?

    internal init(enabled: Set<MFAType>?, preferred: MFAType?) {
        self.enabled = enabled
        self.preferred = preferred
    }

}
