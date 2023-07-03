//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Request for udpating user MFA preferences
public struct UpdateMFAPreferenceRequest: AmplifyOperationRequest {

    public let smsPreference: MFAPreference?
    
    public let totpPreference: MFAPreference?

    /// Extra request options defined in `UpdateMFAPreferenceRequest.Options`
    public var options: Options

    public init(options: Options,
                  smsPreference: MFAPreference?,
                  totpPreference: MFAPreference?) {
        self.options = options
        self.smsPreference = smsPreference
        self.totpPreference = totpPreference
    }
}

public extension UpdateMFAPreferenceRequest {

    struct Options {

        public init() {
            // No options
        }
        
    }
}
