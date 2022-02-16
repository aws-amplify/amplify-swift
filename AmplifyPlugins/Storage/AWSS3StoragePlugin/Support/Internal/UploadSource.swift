//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

enum UploadSource {
    case data(Data)
    case local(URL)

    func getFile(fileSystem: FileSystem = .default) throws -> UploadFile {
        let uploadFile: UploadFile
        switch self {
        case .data(let data):
            let fileURL = try FileSystem.default.createTemporaryFile(data: data)
            let size = fileSystem.getFileSize(fileURL: fileURL)
            uploadFile = .init(fileURL: fileURL, temporaryFileCreated: true, size: size)
        case .local(let fileURL):
            let size = fileSystem.getFileSize(fileURL: fileURL)
            uploadFile = .init(fileURL: fileURL, temporaryFileCreated: false, size: size)
        }
        return uploadFile
    }
}
