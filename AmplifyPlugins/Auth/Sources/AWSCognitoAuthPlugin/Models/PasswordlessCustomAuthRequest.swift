//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

enum PasswordlessCustomAuthSignInMethod: String {
    case otp = "OTP"
    case magicLink = "MAGIC_LINK"
}

enum PasswordlessCustomAuthRequestAction: String {
    case request = "REQUEST"
    case confirm = "CONFIRM"
}

struct PasswordlessCustomAuthRequest {

    let signInMethod: PasswordlessCustomAuthSignInMethod
    let action: PasswordlessCustomAuthRequestAction
    let deliveryMedium: AuthPasswordlessDeliveryDestination?

    init(signInMethod: PasswordlessCustomAuthSignInMethod,
         action: PasswordlessCustomAuthRequestAction,
         deliveryMedium: AuthPasswordlessDeliveryDestination? = nil) {
        self.signInMethod = signInMethod
        self.action = action
        self.deliveryMedium = deliveryMedium
    }

    func toDictionary() -> [String: String] {
        var dictionary = [
            "signInMethod": signInMethod.rawValue,
            "action": action.rawValue
        ]
        if let deliveryMedium = deliveryMedium {
            dictionary["deliveryMedium"] = deliveryMedium.rawValue
        }
        return dictionary
    }
}
