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

    internal let smsPreference: MFAPreference?
    internal let totpPreference: MFAPreference?

    /// Extra request options defined in `FetchMFAPreferenceRequest.Options`
    public var options: Options

    internal init(options: Options,
                  smsPreference: MFAPreference?,
                  totpPreference: MFAPreference?) {
        self.options = options
        self.smsPreference = smsPreference
        self.totpPreference = totpPreference
    }
}

public extension UpdateMFAPreferenceRequest {

    struct Options {

        public init() { }
    }
}
