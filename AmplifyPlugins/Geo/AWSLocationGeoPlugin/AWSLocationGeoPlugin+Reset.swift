//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension AWSLocationGeoPlugin {

    /// Resets the state of the plugin.
    ///
    /// Sets stored objects to nil to allow deallocation, then calls onComplete closure
    /// to signal the reset has completed.
    public func reset(onComplete: @escaping (() -> Void)) {
        locationService = nil
        authService = nil
        pluginConfig = nil

        onComplete()
    }
}
