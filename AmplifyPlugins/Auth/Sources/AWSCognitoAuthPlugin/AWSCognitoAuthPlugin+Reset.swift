//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSCognitoAuthPlugin: Resettable {

    public func reset(onComplete: @escaping BasicClosure) {
        //TODO: Reset other parts
        onComplete()
    }
}
