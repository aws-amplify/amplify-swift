//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.MFAType` and the engine's `EngineMFAType`.
// Case to case, never through `rawValue`, so neither side's string mapping can leak into the other.

extension EngineMFAType {

    init(_ mfaType: MFAType) {
        switch mfaType {
        case .sms: self = .sms
        case .totp: self = .totp
        case .email: self = .email
        }
    }
}

extension MFAType {

    init(_ mfaType: EngineMFAType) {
        switch mfaType {
        case .sms: self = .sms
        case .totp: self = .totp
        case .email: self = .email
        }
    }
}
