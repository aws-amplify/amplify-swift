//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension MFAType {

    init?(mfaValue: String) {

        if mfaValue.caseInsensitiveCompare("SMS_MFA") == .orderedSame {
            self = .sms
        } else if mfaValue.caseInsensitiveCompare("SOFTWARE_TOKEN_MFA") == .orderedSame {
            self = .totp
        } else {
            return nil
        }
        
    }
}
