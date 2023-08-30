//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
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

extension MFAPreference {

    func smsSetting(isCurrentlyPreferred: Bool = false) -> CognitoIdentityProviderClientTypes.SMSMfaSettingsType {
        switch self {
        case .enabled:
            return .init(enabled: true, preferredMfa: isCurrentlyPreferred)
        case .preferred:
            return .init(enabled: true, preferredMfa: true)
        case .notPreferred:
            return .init(enabled: true, preferredMfa: false)
        case .disabled:
            return .init(enabled: false)
        }
    }

    func softwareTokenSetting(isCurrentlyPreferred: Bool = false) -> CognitoIdentityProviderClientTypes.SoftwareTokenMfaSettingsType {
        switch self {
        case .enabled:
            return .init(enabled: true, preferredMfa: isCurrentlyPreferred)
        case .preferred:
            return .init(enabled: true, preferredMfa: true)
        case .notPreferred:
            return .init(enabled: true, preferredMfa: false)
        case .disabled:
            return .init(enabled: false)
        }
    }
}
