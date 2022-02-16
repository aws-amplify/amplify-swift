//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import Amplify
import AWSPluginsCore

struct AWSS3StorageService: AWSS3StorageServiceBehaviour {
    func reset() {
        fatalError("Not Implemented")
    }

    func getEscapeHatch() -> S3Client {
        fatalError("Not Implemented")
    }

    func download(serviceKey: String, fileURL: URL?, onEvent: @escaping StorageServiceDownloadEventHandler) {
        fatalError("Not Implemented")
    }

    func getPreSignedURL(serviceKey: String, expires: Int, onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        fatalError("Not Implemented")
    }

    func upload(serviceKey: String, uploadSource: UploadSource, contentType: String?, metadata: [String : String]?, onEvent: @escaping StorageServiceUploadEventHandler) {
        fatalError("Not Implemented")
    }

    func multiPartUpload(serviceKey: String, uploadSource: UploadSource, contentType: String?, metadata: [String : String]?, onEvent: @escaping StorageServiceMultiPartUploadEventHandler) {
        fatalError("Not Implemented")
    }

    func list(prefix: String, path: String?, onEvent: @escaping StorageServiceListEventHandler) {
        fatalError("Not Implemented")
    }

    func delete(serviceKey: String, onEvent: @escaping StorageServiceDeleteEventHandler) {
        fatalError("Not Implemented")
    }
}

extension AWSS3StorageService {
    public func configure(using configuration: Any?) throws {}
}
