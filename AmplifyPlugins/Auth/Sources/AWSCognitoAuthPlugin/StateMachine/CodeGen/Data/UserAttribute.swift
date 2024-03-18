//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

@_spi(InternalAmplifyConfiguration)
public enum UsernameAttribute: String, Codable {
    case username = "USERNAME"
    case email = "EMAIL"
    case phoneNumber = "PHONE_NUMBER"

    public init?(from authUserAttributeKey: AuthUserAttributeKey) {
        switch authUserAttributeKey {
        case .email:
            self = .email
        case .phoneNumber:
            self = .phoneNumber
        default:
            return nil
        }
    }
}
