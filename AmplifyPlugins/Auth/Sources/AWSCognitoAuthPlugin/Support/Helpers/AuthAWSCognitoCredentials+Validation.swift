//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AuthAWSCognitoCredentials {

    func doesExpire(in seconds: TimeInterval = 0) -> Bool {

        let expiryTime = Date(timeIntervalSinceNow: seconds)
        return (expiration.compare(expiryTime) == .orderedDescending)
    }


}
