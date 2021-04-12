//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCore
import Foundation

class MockAWSSignatureV4Signer: AWSSignatureV4Signer {
    override func interceptRequest(_ request: NSMutableURLRequest!) -> AWSTask<AnyObject>! {
        request.addValue("authorizationValue", forHTTPHeaderField: "Authorization")
        request.addValue("SecurityToken", forHTTPHeaderField: "X-Amz-Security-Token")
        return AWSTask.init(result: request)
    }
}
