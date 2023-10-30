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

        Task {
            do {
                try await awsS3.deleteObject(request)
                onEvent(.completedVoid)
            } catch let error as StorageError {
                onEvent(.failed(error))
            } catch {
                onEvent(.failed(StorageError(error: error)))
            }
        }
    }
}
