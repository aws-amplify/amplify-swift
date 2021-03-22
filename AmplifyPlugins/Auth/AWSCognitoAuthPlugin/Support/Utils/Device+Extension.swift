//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension Device {

    func toAWSAuthDevice() -> AuthDevice {
        let id = deviceKey ?? ""
        let name = ""
        let device = AWSAuthDevice(id: id,
                                   name: name,
                                   attributes: attributes,
                                   createdDate: createDate,
                                   lastAuthenticatedDate: lastAuthenticatedDate,
                                   lastModifiedDate: lastModifiedDate)
        return device
    }
}
