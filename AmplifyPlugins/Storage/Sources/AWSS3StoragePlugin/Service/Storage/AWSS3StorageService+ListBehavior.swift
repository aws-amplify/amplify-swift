//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    func list(prefix: String,
              path: String?,
              onEvent: @escaping StorageServiceListEventHandler) {
        let request = AWSS3ListObjectsV2Request(bucket: bucket, prefix: prefix, path: path)
        awsS3.listObjectsV2(request) { result in
            switch result {
            case .success(let list):
                onEvent(.completed(list))
            case .failure(let error):
                onEvent(.failed(error))
            }
        }
    }

}
