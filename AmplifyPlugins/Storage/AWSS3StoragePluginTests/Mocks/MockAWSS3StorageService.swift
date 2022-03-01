//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import Amplify
import AWSS3
@testable import AWSS3StoragePlugin

public class MockAWSS3StorageService: AWSS3StorageServiceBehaviour {

    // MARK: method call counts

    var downloadCalled = 0
    var getPreSignedURLCalled = 0
    var uploadCalled = 0
    var multiPartUploadCalled = 0
    var listCalled = 0
    var deleteCalled = 0

    // MARK: method arguments

    var downloadServiceKey: String?
    var downloadFileURL: URL?

    var getPreSignedURLServiceKey: String?
    var getPreSignedURLExpires: Int?

    var uploadServiceKey: String?
    var uploadUploadSource: UploadSource?
    var uploadContentType: String?
    var uploadMetadata: [String: String]?

    var multiPartUploadServiceKey: String?
    var multiPartUploadUploadSource: UploadSource?
    var multiPartUploadContentType: String?
    var multiPartUploadMetadata: [String: String]?

    var listPrefix: String?
    var listPath: String?

    var deleteServiceKey: String?

    // MARK: Mock behavior

    // array of StorageEvents to be mocked as the stream of events.
    var storageServiceDownloadEvents: [StorageServiceDownloadEvent]?
    var storageServiceGetPreSignedURLEvents: [StorageServiceGetPreSignedURLEvent]?
    var storageServiceUploadEvents: [StorageServiceUploadEvent]?
    var storageServiceMultiPartUploadEvents: [StorageServiceMultiPartUploadEvent]?
    var storageServiceListEvents: [StorageServiceListEvent]?
    var storageServiceDeleteEvents: [StorageServiceDeleteEvent]?

    // MARK: Mock functionality

    /*
    public func configure(region: AWSRegionType,
                          bucket: String,
                          cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                          identifier: String) throws {
    }
     */

    public func reset() {
    }

    public func download(serviceKey: String, fileURL: URL?, onEvent: @escaping StorageServiceDownloadEventHandler) {
        downloadCalled += 1

        downloadServiceKey = serviceKey
        downloadFileURL = fileURL

        for event in storageServiceDownloadEvents ?? [] {
            onEvent(event)
        }
    }

    public func getPreSignedURL(serviceKey: String,
                         method: AWSS3HttpMethod = .get,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        getPreSignedURLCalled += 1

        getPreSignedURLServiceKey = serviceKey
        getPreSignedURLExpires = expires

        for event in storageServiceGetPreSignedURLEvents ?? [] {
            onEvent(event)
        }
    }

    public func upload(serviceKey: String,
                       uploadSource: UploadSource,
                       contentType: String?,
                       metadata: [String: String]?,
                       onEvent: @escaping StorageServiceUploadEventHandler) {
        uploadCalled += 1

        uploadServiceKey = serviceKey
        uploadUploadSource = uploadSource
        uploadContentType = contentType
        uploadMetadata = metadata

        for event in storageServiceUploadEvents ?? [] {
            onEvent(event)
        }
    }

    public func multiPartUpload(serviceKey: String,
                                uploadSource: UploadSource,
                                contentType: String?,
                                metadata: [String: String]?,
                                onEvent: @escaping StorageServiceMultiPartUploadEventHandler) {
        multiPartUploadCalled += 1

        multiPartUploadServiceKey = serviceKey
        multiPartUploadUploadSource = uploadSource
        multiPartUploadContentType = contentType
        multiPartUploadMetadata = metadata

        for event in storageServiceMultiPartUploadEvents ?? [] {
            onEvent(event)
        }
    }

    public func list(prefix: String, path: String?, onEvent: @escaping StorageServiceListEventHandler) {
        listCalled += 1

        listPrefix = prefix
        listPath = path

        for event in storageServiceListEvents ?? [] {
            onEvent(event)
        }
    }

    public func delete(serviceKey: String, onEvent: @escaping StorageServiceDeleteEventHandler) {
        deleteCalled += 1

        deleteServiceKey = serviceKey

        for event in storageServiceDeleteEvents ?? [] {
            onEvent(event)
        }
    }

    public func getEscapeHatch() -> S3Client {
        fatalError("Not Implemented")
    }

    // MARK: Mock verify

    public func verifyDownload(serviceKey: String, fileURL: URL?) {
        XCTAssertEqual(downloadCalled, 1)
        XCTAssertEqual(downloadServiceKey, serviceKey)
        XCTAssertEqual(downloadFileURL, fileURL)
    }

    public func verifyGetPreSignedURL(serviceKey: String,
                                      expires: Int?) {
        getPreSignedURLCalled += 1

        XCTAssertEqual(getPreSignedURLServiceKey, serviceKey)
        XCTAssertEqual(getPreSignedURLExpires, expires)
    }

    public func verifyUpload(serviceKey: String,
                             key: String,
                             uploadSource: UploadSource,
                             contentType: String?,
                             metadata: [String: String]?) {
        XCTAssertEqual(uploadCalled, 1)
        XCTAssertEqual(uploadServiceKey, serviceKey)
        if let uploadUploadSource = uploadUploadSource {
            var uploadSourceEqual = false
            if case .data = uploadSource, case .data = uploadUploadSource {
                uploadSourceEqual = true
            }
            if case .local = uploadSource, case .local = uploadUploadSource {
                uploadSourceEqual = true
            }
            XCTAssertTrue(uploadSourceEqual)
        } else {
            XCTFail("uploadSource is empty")
        }

        XCTAssertEqual(uploadContentType, contentType)
        XCTAssertEqual(uploadMetadata, metadata)
    }

    public func verifyMultiPartUpload(serviceKey: String,
                                      key: String,
                                      uploadSource: UploadSource,
                                      contentType: String?,
                                      metadata: [String: String]?) {
        XCTAssertEqual(multiPartUploadCalled, 1)

        XCTAssertEqual(multiPartUploadServiceKey, serviceKey)
        if let multiPartUploadUploadSource = multiPartUploadUploadSource {
            var uploadSourceEqual = false
            if case .data = uploadSource, case .data = multiPartUploadUploadSource {
                uploadSourceEqual = true
            }
            if case .local = uploadSource, case .local = multiPartUploadUploadSource {
                uploadSourceEqual = true
            }
            XCTAssertTrue(uploadSourceEqual)
        } else {
            XCTFail("uploadSource is empty")
        }
        XCTAssertEqual(multiPartUploadContentType, contentType)
        XCTAssertEqual(multiPartUploadMetadata, metadata)
    }

    public func verifyList(prefix: String, path: String?) {
        XCTAssertEqual(listCalled, 1)

        XCTAssertEqual(listPrefix, prefix)
        XCTAssertEqual(listPath, path)
    }

    public func verifyDelete(serviceKey: String) {
        XCTAssertEqual(deleteCalled, 1)

        XCTAssertEqual(deleteServiceKey, serviceKey)
    }
}
