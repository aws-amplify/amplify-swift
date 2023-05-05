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
    var interactions: [String] = []
    var downloadCalled = 0
    var uploadCalled = 0
    var multiPartUploadCalled = 0
    var deleteCalled = 0

    // MARK: method arguments

    var downloadServiceKey: String?
    var downloadFileURL: URL?

    var uploadServiceKey: String?
    var uploadUploadSource: UploadSource?
    var uploadContentType: String?
    var uploadMetadata: [String: String]?

    var multiPartUploadServiceKey: String?
    var multiPartUploadUploadSource: UploadSource?
    var multiPartUploadContentType: String?
    var multiPartUploadMetadata: [String: String]?

    var deleteServiceKey: String?

    // MARK: Mock behavior

    // array of StorageEvents to be mocked as the stream of events.
    var storageServiceDownloadEvents: [StorageServiceDownloadEvent]?
    var storageServiceUploadEvents: [StorageServiceUploadEvent]?
    var storageServiceMultiPartUploadEvents: [StorageServiceMultiPartUploadEvent]?
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
        interactions.append(#function)
    }

    public func download(serviceKey: String, fileURL: URL?, onEvent: @escaping StorageServiceDownloadEventHandler) {
        interactions.append(#function)
        downloadCalled += 1

        downloadServiceKey = serviceKey
        downloadFileURL = fileURL

        for event in storageServiceDownloadEvents ?? [] {
            onEvent(event)
        }
    }

    var getPreSignedURLHandler: (String, AWSS3SigningOperation, Int) async throws -> URL = { (_, _, _) in
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

    public func getPreSignedURL(serviceKey: String, signingOperation: AWSS3SigningOperation, expires: Int) async throws -> URL {
        interactions.append("\(#function) \(serviceKey) \(signingOperation) \(expires)")
        return try await getPreSignedURLHandler(serviceKey, signingOperation, expires)
    }

    var validateObjectExistenceHandler: (String) async throws -> Void = { _ in }

    public func validateObjectExistence(serviceKey: String) async throws {
        interactions.append("\(#function) \(serviceKey)")
        try await validateObjectExistenceHandler(serviceKey)
    }

    public func upload(serviceKey: String,
                       uploadSource: UploadSource,
                       contentType: String?,
                       metadata: [String: String]?,
                       onEvent: @escaping StorageServiceUploadEventHandler) {
        interactions.append(#function)
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
        interactions.append(#function)
        multiPartUploadCalled += 1

        multiPartUploadServiceKey = serviceKey
        multiPartUploadUploadSource = uploadSource
        multiPartUploadContentType = contentType
        multiPartUploadMetadata = metadata

        for event in storageServiceMultiPartUploadEvents ?? [] {
            onEvent(event)
        }
    }

    enum ListError: Error {
        case unimplemented
    }

    var listHandler: (String, StorageListRequest.Options) async throws -> StorageListResult = { (_, _) in
        throw ListError.unimplemented
    }

    public func list(prefix: String, options: StorageListRequest.Options) async throws -> StorageListResult {
        interactions.append("\(#function) \(prefix)")
        return try await listHandler(prefix, options)
    }

    public func delete(serviceKey: String, onEvent: @escaping StorageServiceDeleteEventHandler) {
        interactions.append(#function)
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

    public func verifyDelete(serviceKey: String) {
        XCTAssertEqual(deleteCalled, 1)

        XCTAssertEqual(deleteServiceKey, serviceKey)
    }
}
