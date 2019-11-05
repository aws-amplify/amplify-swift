//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCore

@testable import AWSPluginsCore
import AWSMobileClient

class MockAWSMobileClient: AWSMobileClientBehavior {
    func getTokens(completionHandler: @escaping (Tokens?, Error?) -> Void) {
        completionHandler(nil, nil)
    }

    public func getCognitoCredentialsProvider() -> AWSCognitoCredentialsProvider {
        return AWSCognitoCredentialsProvider()
    }

    public func getIdentityId() -> AWSTask<NSString> {
        return AWSTask<NSString>()
    }
}
