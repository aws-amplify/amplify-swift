//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

class StorageRequestUtils {
    static let metadataKeyPrefix = "x-amz-meta-"
    static let dataSizeThreshold = 10000000 // 10MB

    static func isLargeUpload(_ uploadSource: UploadSource) -> Result<Bool, StoragePutError> {

        switch uploadSource {
        case .file(let file):
            if let error = validateFileExists(file) {
                return .failure(StoragePutError.missingFile(error.errorDescription, error.recoverySuggestion))
            }

            do {
                let attributeOfItem = try FileManager.default.attributesOfItem(atPath: file.path)
                guard let fileSize = attributeOfItem[FileAttributeKey.size] as? UInt64 else {
                    return .failure(StoragePutError.unknown("file Issue", "File Issue"))
                }
                if fileSize > dataSizeThreshold {
                    return .success(true)
                }
            } catch {
                return .failure(StoragePutError.unknown("File issue", "file issue"))
            }

        case .data(let data):
            if data.count > dataSizeThreshold {
                return .success(true)
            }
        }

        return .success(false)
    }

}
