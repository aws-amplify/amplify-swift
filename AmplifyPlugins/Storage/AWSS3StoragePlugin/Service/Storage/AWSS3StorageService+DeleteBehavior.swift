//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    func delete(serviceKey: String, onEvent: @escaping StorageServiceDeleteEventHandler) {
        let request = AWSS3DeleteObjectRequest(bucket: bucket, key: serviceKey)

        awsS3.deleteObject(request) { result in
            switch result {
            case .success:
                onEvent(StorageEvent.completedVoid)
            case .failure(let error):
                onEvent(StorageEvent.failed(error))
            }
        }
    }

}
