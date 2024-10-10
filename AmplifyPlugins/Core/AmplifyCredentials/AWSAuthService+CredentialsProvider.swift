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

extension AWSAuthService: AWSAuthCredentialsProviderBehavior {
    public func getCredentialsProvider() -> AWSClientRuntime.CredentialsProviding {
        return AmplifyAWSCredentialsProvider()
    }
}
