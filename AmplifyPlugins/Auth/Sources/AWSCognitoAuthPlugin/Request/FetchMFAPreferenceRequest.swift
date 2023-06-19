//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Request for fetching user MFA preferences
public struct FetchMFAPreferenceRequest: AmplifyOperationRequest {

    /// Extra request options defined in `FetchMFAPreferenceRequest.Options`
    public var options: Options

    internal init(options: Options) {
        self.options = options
    }
}

public extension FetchMFAPreferenceRequest {

    struct Options {

        public init() { }
    }
}
