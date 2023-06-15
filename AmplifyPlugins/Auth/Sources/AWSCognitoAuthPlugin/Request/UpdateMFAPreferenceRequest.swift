//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Request for fetching user MFA preferences
public struct UpdateMFAPreferenceRequest: AmplifyOperationRequest {

    /// Extra request options defined in `FetchMFAPreferenceRequest.Options`
    public var options: Options

    public init(options: Options) {
        self.options = options
    }
}

public extension UpdateMFAPreferenceRequest {

    struct Options {

        public init() { }
    }
}
