//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSPluginsCore
import Foundation

public protocol AWSAuthCredentialsProviderBehavior: AWSAuthServiceBehavior {
    func getCredentialsProvider() -> CredentialsProviding
}


