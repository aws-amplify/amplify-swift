//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSS3StoragePlugin
import AWSS3

public class MockAWSMobileClient: AWSMobileClientBehavior {
    public func getIdentityId() -> AWSTask<NSString> {
        return AWSTask<NSString>()
    }

}
