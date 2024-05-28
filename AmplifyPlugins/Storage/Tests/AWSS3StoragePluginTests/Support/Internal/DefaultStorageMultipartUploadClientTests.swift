//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import func AmplifyTestCommon.XCTAssertThrowFatalError
@testable import AWSS3StoragePlugin
import AWSS3
import XCTest

class DefaultStorageMultipartUploadClientTests: XCTestCase {
    private var defaultClient: DefaultStorageMultipartUploadClient!
    private var serviceProxy: MockStorageServiceProxy!
    private var session: MockStorageMultipartUploadSession!
    private var awss3Behavior: MockAWSS3Behavior!
    private var uploadFile: UploadFile!

    override func setUp() async throws {
        awss3Behavior = MockAWSS3Behavior()
        serviceProxy = MockStorageServiceProxy(
            awsS3: awss3Behavior
        )
        let tempFileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("txt")
        try "Hello World".write(to: tempFileURL, atomically: true, encoding: .utf8)
        uploadFile = UploadFile(
            fileURL: tempFileURL,
            temporaryFileCreated: false,
            size: 88
        )
        defaultClient = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        session = MockStorageMultipartUploadSession(
            client: client,
            bucket: "bucket",
            key: "key",
            onEvent: { event in }
        )
        client.integrate(session: session)
    }

    private var client: StorageMultipartUploadClient! {
        defaultClient
    }

    override func tearDown() {
        defaultClient = nil
        serviceProxy = nil
        session = nil
        awss3Behavior = nil
        uploadFile = nil
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: createMultipartUpload is invoked and AWSS3Behavior returns .success
    /// Then: A .created event is reported to the session and the session is registered
    func testCreateMultipartUpload_withSuccess_shouldSucceed() async throws {
        awss3Behavior.createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awss3Behavior.createMultipartUploadResult = .success(.init(
            bucket: "bucket",
            key: "key",
            uploadId: "uploadId"
        ))
        try client.createMultipartUpload()

        await fulfillment(of: [awss3Behavior.createMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.createMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 2)
        XCTAssertEqual(session.failCount, 0)
        if case .created(let uploadFile, let uploadId) = try XCTUnwrap(session.lastMultipartUploadEvent) {
            XCTAssertEqual(uploadFile.fileURL, uploadFile.fileURL)
            XCTAssertEqual(uploadId, "uploadId")
        }
        XCTAssertEqual(serviceProxy.registerMultipartUploadSessionCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: createMultipartUpload is invoked and AWSS3Behavior returns .failure
    /// Then: An .unknown error is reported to the session and the session is not registered
    func testCreateMultipartUpload_withError_shouldFail() async throws {
        awss3Behavior.createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awss3Behavior.createMultipartUploadResult = .failure(.unknown("Unknown Error", nil))
        try client.createMultipartUpload()

        await fulfillment(of: [awss3Behavior.createMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.createMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 1)
        XCTAssertEqual(session.failCount, 1)
        if case .unknown(let description, _) = try XCTUnwrap(session.lastError) as? StorageError {
            XCTAssertEqual(description, "Unknown Error")
        }
        XCTAssertEqual(serviceProxy.registerMultipartUploadSessionCount, 0)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: serviceProxy is set to nil and createMultipartUpload is invoked
    /// Then: A fatal error is thrown
    func testCreateMultipartUpload_withoutServiceProxy_shouldThrowFatalError() throws {
        serviceProxy = nil
        try XCTAssertThrowFatalError {
            try? self.client.createMultipartUpload()
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: uploadPart is invoked with valid parts
    /// Then: A .started event is reported to the session
    func testUploadPart_withParts_shouldSucceed() async throws {
        session.handleUploadPartExpectation = expectation(description: "Upload Part with parts")

        try client.uploadPart(
            partNumber: 1,
            multipartUpload: .parts(
                uploadId: "uploadId",
                uploadFile: uploadFile,
                partSize: .default,
                parts: [
                    .pending(bytes: 10),
                    .pending(bytes: 20)
                ]
            ),
            subTask: .init(
                transferType: .upload(onEvent: { event in }),
                bucket: "bucket",
                key: "key"
            )
        )

        await fulfillment(of: [session.handleUploadPartExpectation!], timeout: 1)
        XCTAssertEqual(session.handleUploadPartCount, 1)
        XCTAssertEqual(session.failCount, 0)
        if case .started(let partNumber, _) = try XCTUnwrap(session.lastUploadEvent) {
            XCTAssertEqual(partNumber, 1)
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: uploadPart is invoked with a non-existing file
    /// Then: An error is reported to the session
    func testUploadPart_withInvalidFile_shouldFail() async throws {
        session.failExpectation = expectation(description: "Upload Part with invalid file")

        try client.uploadPart(
            partNumber: 1,
            multipartUpload: .parts(
                uploadId: "uploadId",
                uploadFile: .init(
                    fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("noFile.txt"),
                    temporaryFileCreated: false,
                    size: 1024),
                partSize: .default,
                parts: [
                    .pending(bytes: 10),
                    .pending(bytes: 20)
                ]
            ),
            subTask: .init(
                transferType: .upload(onEvent: { event in }),
                bucket: "bucket",
                key: "key"
            )
        )

        await fulfillment(of: [session.failExpectation!], timeout: 1)
        XCTAssertEqual(session.handleUploadPartCount, 0)
        XCTAssertEqual(session.failCount, 1)
        XCTAssertNil(session.lastUploadEvent)
        XCTAssertNotNil(session.lastError)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: serviceProxy is set to nil and uploadPart is invoked
    /// Then: A fatal error is thrown
    func testUploadPart_withoutServiceProxy_shouldThrowFatalError() throws {
        self.serviceProxy = nil
        try XCTAssertThrowFatalError {
            try? self.client.uploadPart(
                partNumber: 1,
                multipartUpload: .parts(
                    uploadId: "uploadId",
                    uploadFile: self.uploadFile,
                    partSize: .default,
                    parts: [
                        .pending(bytes: 10),
                        .pending(bytes: 20)
                    ]
                ),
                subTask: .init(
                    transferType: .upload(onEvent: { event in }),
                    bucket: "bucket",
                    key: "key"
                )
            )
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: uploadPart is invoked without parts
    /// Then: A fatal error is thrown
    func testUploadPart_withoutParts_shouldThrowFatalError() throws {
        try XCTAssertThrowFatalError {
            try? self.client.uploadPart(
                partNumber: 1,
                multipartUpload: .created(
                    uploadId: "uploadId",
                    uploadFile: self.uploadFile
                ),
                subTask: .init(
                    transferType: .upload(onEvent: { event in }),
                    bucket: "bucket",
                    key: "key"
                )
            )
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: completeMultipartUpload is invoked and AWSS3Behaviour returns succees
    /// Then: A .completed event is reported to the session and the session is unregistered
    func testCompleteMultipartUpload_withSuccess_shouldSucceed() async throws {
        awss3Behavior.completeMultipartUploadExpectation = expectation(description: "Complete Multipart Upload")
        awss3Behavior.completeMultipartUploadResult = .success(.init(
            bucket: "bucket",
            key: "key",
            eTag: "eTag"
        ))
        try client.completeMultipartUpload(uploadId: "uploadId")

        await fulfillment(of: [awss3Behavior.completeMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.completeMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 1)
        XCTAssertEqual(session.failCount, 0)
        if case .completed(let uploadId) = try XCTUnwrap(session.lastMultipartUploadEvent) {
            XCTAssertEqual(uploadId, "uploadId")
        }
        XCTAssertEqual(serviceProxy.unregisterMultipartUploadSessionCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: completeMultipartUpload is invoked and AWSS3Behaviour returns failure
    /// Then: A .unknown error is reported to the session and the session is not unregistered
    func testCompleteMultipartUpload_withError_shouldFail() async throws {
        awss3Behavior.completeMultipartUploadExpectation = expectation(description: "Complete Multipart Upload")
        awss3Behavior.completeMultipartUploadResult = .failure(.unknown("Unknown Error", nil))
        try client.completeMultipartUpload(uploadId: "uploadId")

        await fulfillment(of: [awss3Behavior.completeMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.completeMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
        XCTAssertEqual(session.failCount, 1)
        if case .unknown(let description, _) = try XCTUnwrap(session.lastError) as? StorageError {
            XCTAssertEqual(description, "Unknown Error")
        }
        XCTAssertEqual(serviceProxy.unregisterMultipartUploadSessionCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: serviceProxy is set to nil and completeMultipartUpload is invoked
    /// Then: A fatal error is thrown
    func testCompleteMultipartUpload_withoutServiceProxy_shouldThrowFatalError() throws {
        serviceProxy = nil
        try XCTAssertThrowFatalError {
            try? self.client.completeMultipartUpload(uploadId: "uploadId")
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: abortMultipartUpload is invoked and AWSS3Behaviour returns success
    /// Then: An .aborted event is reported to the session and the session is unregistered
    func testAbortMultipartUpload_withSuccess_shouldSucceed() async throws {
        awss3Behavior.abortMultipartUploadExpectation = expectation(description: "Abort Multipart Upload")
        awss3Behavior.abortMultipartUploadResult = .success(())
        try client.abortMultipartUpload(uploadId: "uploadId", error: CancellationError())

        await fulfillment(of: [awss3Behavior.abortMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.abortMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 1)
        XCTAssertEqual(session.failCount, 0)
        if case .aborted(let uploadId, let error) = try XCTUnwrap(session.lastMultipartUploadEvent) {
            XCTAssertEqual(uploadId, "uploadId")
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertEqual(serviceProxy.unregisterMultipartUploadSessionCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: abortMultipartUpload is invoked and AWSS3Behaviour returns failure
    /// Then: A .unknown error is reported to the session and the session is not unregistered
    func testAbortMultipartUpload_withError_shouldFail() async throws {
        awss3Behavior.abortMultipartUploadExpectation = expectation(description: "Abort Multipart Upload")
        awss3Behavior.abortMultipartUploadResult = .failure(.unknown("Unknown Error", nil))
        try client.abortMultipartUpload(uploadId: "uploadId")

        await fulfillment(of: [awss3Behavior.abortMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.abortMultipartUploadCount, 1)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
        XCTAssertEqual(session.failCount, 1)
        if case .unknown(let description, _) = try XCTUnwrap(session.lastError) as? StorageError {
            XCTAssertEqual(description, "Unknown Error")
        }
        XCTAssertEqual(serviceProxy.unregisterMultipartUploadSessionCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: serviceProxy is set to nil and abortMultipartUpload is invoked
    /// Then: A fatal error is thrown
    func testAbortMultipartUpload_withoutServiceProxy_shouldThrowFatalError() throws {
        serviceProxy = nil
        try XCTAssertThrowFatalError {
            try? self.client.abortMultipartUpload(uploadId: "uploadId")
        }
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: cancelUploadTasks is invoked with identifiers
    /// Then: The tasks are unregistered
    func testCancelUploadTasks_shouldSucceed() async throws {
        let cancelExpectation = expectation(description: "Cancel Upload Tasks")
        client.cancelUploadTasks(taskIdentifiers: [0, 1,2], done: {
            cancelExpectation.fulfill()
        })

        await fulfillment(of: [cancelExpectation], timeout: 1)
        XCTAssertEqual(serviceProxy.unregisterTaskIdentifiersCount, 1)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: filter is invoked with some disallowed values
    /// Then: a  dictionary is returned with the disallowed values removed
    func testFilterRequestHeaders_shouldResultFilteredHeaders() {
        let filteredHeaders = defaultClient.filter(
            requestHeaders: [
                "validHeader": "validValue",
                "x-amz-acl": "invalidValue",
                "x-amz-tagging": "invalidValue",
                "x-amz-storage-class": "invalidValue",
                "x-amz-server-side-encryption": "invalidValue",
                "x-amz-meta-invalid_one": "invalidValue",
                "x-amz-meta-invalid_two": "invalidValue",
                "x-amz-grant-invalid_one": "invalidvalue",
                "x-amz-grant-invalid_two": "invalidvalue"
            ]
        )

        XCTAssertEqual(filteredHeaders.count, 1)
        XCTAssertEqual(filteredHeaders["validHeader"], "validValue")
    }
}

private class MockStorageServiceProxy: StorageServiceProxy {
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior! = MockAWSS3PreSignedURLBuilder()
    var awsS3: AWSS3Behavior!
    var urlSession = URLSession.shared
    var userAgent: String = ""
    var urlRequestDelegate: URLRequestDelegate? = nil

    init(awsS3: AWSS3Behavior) {
        self.awsS3 = awsS3
    }

    func register(task: StorageTransferTask) {}

    func unregister(task: StorageTransferTask) {}

    var unregisterTaskIdentifiersCount = 0
    func unregister(taskIdentifiers: [TaskIdentifier]) {
        unregisterTaskIdentifiersCount += 1
    }

    var registerMultipartUploadSessionCount = 0
    func register(multipartUploadSession: StorageMultipartUploadSession) {
        registerMultipartUploadSessionCount += 1
    }

    var unregisterMultipartUploadSessionCount = 0
    func unregister(multipartUploadSession: StorageMultipartUploadSession) {
        unregisterMultipartUploadSessionCount += 1
    }
}

private class MockAWSS3Behavior: AWSS3Behavior {
    func deleteObject(_ request: AWSS3DeleteObjectRequest, completion: @escaping (Result<Void, StorageError>) -> Void) {}

    func listObjectsV2(_ request: AWSS3ListObjectsV2Request, completion: @escaping (Result<StorageListResult, StorageError>) -> Void) {}

    var createMultipartUploadCount = 0
    var createMultipartUploadResult: Result<AWSS3CreateMultipartUploadResponse, StorageError>? = nil
    var createMultipartUploadExpectation: XCTestExpectation? = nil
    func createMultipartUpload(_ request: CreateMultipartUploadRequest, completion: @escaping (Result<AWSS3CreateMultipartUploadResponse, StorageError>) -> Void) {
        createMultipartUploadCount += 1
        if let result = createMultipartUploadResult {
            completion(result)
        }
        createMultipartUploadExpectation?.fulfill()
    }

    var completeMultipartUploadCount = 0
    var completeMultipartUploadResult: Result<AWSS3CompleteMultipartUploadResponse, StorageError>? = nil
    var completeMultipartUploadExpectation: XCTestExpectation? = nil
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest, completion: @escaping (Result<AWSS3CompleteMultipartUploadResponse, StorageError>) -> Void) {
        completeMultipartUploadCount += 1
        if let result = completeMultipartUploadResult {
            completion(result)
        }
        completeMultipartUploadExpectation?.fulfill()
    }

    var abortMultipartUploadCount = 0
    var abortMultipartUploadResult: Result<Void, StorageError>? = nil
    var abortMultipartUploadExpectation: XCTestExpectation? = nil
    func abortMultipartUpload(_ request: AWSS3AbortMultipartUploadRequest, completion: @escaping (Result<Void, StorageError>) -> Void) {
        abortMultipartUploadCount += 1
        if let result = abortMultipartUploadResult {
            completion(result)
        }
        abortMultipartUploadExpectation?.fulfill()
    }

    func getS3() -> S3ClientProtocol {
        return MockS3Client()
    }
}

class MockStorageMultipartUploadSession: StorageMultipartUploadSession {
    var handleMultipartUploadCount = 0
    var lastMultipartUploadEvent: StorageMultipartUploadEvent? = nil
    override func handle(multipartUploadEvent: StorageMultipartUploadEvent) {
        handleMultipartUploadCount += 1
        lastMultipartUploadEvent = multipartUploadEvent
    }

    var handleUploadPartCount = 0
    var lastUploadEvent: StorageUploadPartEvent? = nil
    var handleUploadPartExpectation: XCTestExpectation? = nil

    override func handle(uploadPartEvent: StorageUploadPartEvent) {
        handleUploadPartCount += 1
        lastUploadEvent = uploadPartEvent
        handleUploadPartExpectation?.fulfill()
    }

    var failCount = 0
    var lastError: Error? = nil
    var failExpectation: XCTestExpectation? = nil
    override func fail(error: Error) {
        failCount += 1
        lastError = error
        failExpectation?.fulfill()
    }
}
