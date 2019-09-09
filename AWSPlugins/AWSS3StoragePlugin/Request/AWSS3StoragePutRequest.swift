//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AWSS3StoragePutRequest {
    let accessLevel: StorageAccessLevel
    let key: String
    let uploadSource: UploadSource
    let contentType: String?
    let metadata: [String: String]?
    let options: Any?

    init(accessLevel: StorageAccessLevel,
         key: String,
         uploadSource: UploadSource,
         contentType: String?,
         metadata: [String: String]?,
         options: Any?) {
        self.accessLevel = accessLevel
        self.key = key
        self.uploadSource = uploadSource
        self.contentType = contentType
        self.metadata = metadata
        self.options = options
    }

    func validate() -> StoragePutError? {
        if key.isEmpty {
            return StoragePutError.validation(StorageErrorConstants.KeyIsEmpty.ErrorDescription,
                                              StorageErrorConstants.KeyIsEmpty.RecoverySuggestion)
        }

        if let contentType = contentType {
            if contentType.isEmpty {
                return StoragePutError.validation(StorageErrorConstants.ContentTypeIsEmpty.ErrorDescription,
                                               StorageErrorConstants.ContentTypeIsEmpty.RecoverySuggestion)
            }
            // else if contentTypeValidator(contentType) {
        }

        return nil
    }

    func isLargeUpload() -> Bool {
        // TODO: The request contains context on what is considered a large upload like data size
        return false
    }
}
