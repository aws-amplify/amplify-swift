//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3
@testable import AWSS3StoragePlugin

public class MockAWSS3StorageService: AWSS3StorageServiceBehaviour {

    private(set) public var downloadDataCalled: Bool?
    private(set) public var downloadToFileCalled: Bool?
    private(set) public var getPreSignedURLCalled: Bool?
    private(set) public var uploadCalled: Bool?
    private(set) public var multiPartUploadCalled: Bool?
    private(set) public var listCalled: Bool?
    private(set) public var deleteCalled: Bool?

    private var mockS3: AWSS3Behavior = MockS3()

    public func configure(region: AWSRegionType,
                          bucket: String,
                          cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                          identifier: String) throws {
    }

    public func reset() {
    }

    public func download(serviceKey: String, fileURL: URL?, onEvent: @escaping StorageDownloadOnEventHandler) {

        if fileURL != nil {
            downloadToFileCalled = true
        } else {
            downloadDataCalled = true
        }

        let data = Data()
        onEvent(StorageEvent.completed(StorageGetResult(data: data)))
    }

    public func getPreSignedURL(serviceKey: String,
                                expires: Int?,
                                onEvent: @escaping StorageGetPreSignedUrlOnEventHandler) {
        getPreSignedURLCalled = true

        let url = URL(fileURLWithPath: "path")
        onEvent(StorageEvent.completed(StorageGetResult(remote: url)))
    }

    public func upload(serviceKey: String,
                       key: String,
                       uploadSource: UploadSource,
                       contentType: String?,
                       onEvent: @escaping StorageUploadOnEventHandler) {
        uploadCalled = true

        onEvent(StorageEvent.completed(StoragePutResult(key: key)))
    }

    public func multiPartUpload(serviceKey: String,
                                key: String,
                                uploadSource: UploadSource,
                                contentType: String?,
                                onEvent: @escaping StorageMultiPartUploadOnEventHandler) {
        multiPartUploadCalled = true

        onEvent(StorageEvent.completed(StoragePutResult(key: key)))
    }

    public func list(prefix: String, onEvent: @escaping StorageListOnEventHandler) {
        listCalled = true

        onEvent(StorageEvent.completed(StorageListResult(keys: [])))
    }

    public func delete(serviceKey: String, onEvent: @escaping StorageDeleteOnEventHandler) {
        deleteCalled = true
        onEvent(StorageEvent.completed(StorageRemoveResult(key: serviceKey)))
    }

    public func getEscapeHatch() -> AWSS3 {
        return mockS3.getS3()
    }
}
