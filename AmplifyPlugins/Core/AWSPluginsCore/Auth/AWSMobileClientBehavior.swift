//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

// Behavior that the implemenation class for AWSMobileClient will use.
protocol AWSMobileClientBehavior {

    // Returns a `AWSCognitoCredentialsProvider`, used to instantiate other dependencies with.
    func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider

    // Returns the unique identifier for the user
    func getIdentityId() -> AWSTask<NSString>
}
