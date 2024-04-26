//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime

public protocol AWSAuthCredentialsProviderBehavior {
    func getCredentialsProvider() -> CredentialsProviding
}
