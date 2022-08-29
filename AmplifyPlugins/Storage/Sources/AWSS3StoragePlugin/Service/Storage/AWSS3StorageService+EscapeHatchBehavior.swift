//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3

extension AWSS3StorageService {

    func getEscapeHatch() -> S3Client {
        s3Client
    }

}
