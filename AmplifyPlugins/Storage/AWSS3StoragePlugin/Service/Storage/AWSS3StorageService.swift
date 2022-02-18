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

class AWSS3StorageService: AWSS3StorageServiceBehaviour {
    private var authService: AWSAuthServiceBehavior?

    // resettable values
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    var awsS3: AWSS3Behavior!
    var region: String!
    var bucket: String!
    var identifier: String!

    init(authService: AWSAuthServiceBehavior, region: String, bucket: String, identifier: String) {
        self.authService = authService

        self.preSignedURLBuilder = AWSS3PreSignedURLBuilderAdapter(authService: authService, signingRegion: region)
        self.awsS3 = try! AWSS3Adapter(S3Client(region: region))

        self.region = region
        self.bucket = bucket
        self.identifier = identifier
    }

    func reset() {
        preSignedURLBuilder = nil
        awsS3 = nil
        region = nil
        bucket = nil
        identifier = nil
    }

    func getEscapeHatch() -> S3Client {
        awsS3.getS3()
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

}
