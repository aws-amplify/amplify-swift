//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

extension AWSS3StorageService {

    func reset() {
        AWSS3TransferUtility.remove(forKey: identifier)
        transferUtility = nil
        AWSS3PreSignedURLBuilder.remove(forKey: identifier)
        preSignedURLBuilder = nil
        AWSS3.remove(forKey: identifier)
        awsS3 = nil
        bucket = nil
        identifier = nil
    }
}
