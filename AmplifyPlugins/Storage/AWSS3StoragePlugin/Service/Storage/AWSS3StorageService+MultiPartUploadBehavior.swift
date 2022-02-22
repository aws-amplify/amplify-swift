//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import Amplify

extension AWSS3StorageService {

    func multiPartUpload(serviceKey: String,
                         uploadSource: UploadSource,
                         contentType: String?,
                         metadata: [String: String]?,
                         onEvent: @escaping StorageServiceMultiPartUploadEventHandler) {
        let fail: (Error) -> Void = { error in
            let storageError = StorageError(error: error)
            onEvent(.failed(storageError))
        }

        // Validate parameters
        guard attempt(try validateParameters(bucket: bucket, key: serviceKey, accelerationModeEnabled: false), fail: fail) else { return }

        let requestHeaders: [String: String] = [:]

        // Get file using upload source
        guard let uploadFile = attempt(try uploadSource.getFile(), fail: fail) else { return }

        let client = DefaultStorageMultipartUploadClient(serviceProxy: self,
                                                         bucket: bucket,
                                                         key: serviceKey,
                                                         uploadFile: uploadFile)
        let multipartUploadSession = StorageMultipartUploadSession(client: client,
                                                                   bucket: bucket,
                                                                   key: serviceKey,
                                                                   contentType: contentType,
                                                                   requestHeaders: requestHeaders,
                                                                   onEvent: onEvent)

        register(multipartUploadSession: multipartUploadSession)

        // https://docs.amplify.aws/sdk/storage/transfer-utility/q/platform/ios
        multipartUploadSession.startUpload()
    }

}
