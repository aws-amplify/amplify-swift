//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSClientRuntime
import AWSPluginsCore

public protocol AWSAuthCredentialsProviderBehavior: AWSAuthServiceBehavior {
    func getCredentialsProvider() -> CredentialsProviding
}


