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
        var isLargeUpload = false
        switch uploadSource {
        case .file(let file):
            do {
                let attr = try FileManager.default.attributesOfItem(atPath: file.path)
                if let fileSize = attr[FileAttributeKey.size] as? UInt64 {
                    print("Got file size: \(fileSize)")
                    if fileSize > 10000000 {
                        isLargeUpload = true
                    }
                }
            } catch {
                print("ErrorGettingFileSize: \(error)")
            }
        case .data(let data):
            let dataCount = data.count
            print("Got data size: \(dataCount)")
            if dataCount > 10000000 { // 10000000 = 10 MB
                isLargeUpload = true
            }
        }

        return isLargeUpload
    }
}
