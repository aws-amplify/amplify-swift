//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient
import Amplify

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
