//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

extension AuthUserAttribute {
    
    func sdkClientAttributeType() -> CognitoIdentityProviderClientTypes.AttributeType {
        CognitoIdentityProviderClientTypes.AttributeType(name:key.rawValue, value: value)
    }
    
}
