//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import XCTest
@testable import Amplify
@testable import func AmplifyTestCommon.XCTAssertNoThrowFatalError
@testable import AWSS3StoragePlugin

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class DefaultStorageMultipartUploadClientTests: XCTestCase, @unchecked Sendable {
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
    /// Then: A StorageError is thrown, and nothing is sent or reported to the session
    func testCreateMultipartUpload_withoutServiceProxy_shouldThrowStorageError() throws {
        serviceProxy = nil
        let error = try errorThrown { try self.client.createMultipartUpload() }
        XCTAssertTrue(error is StorageError)
        XCTAssertEqual(awss3Behavior.createMultipartUploadCount, 0)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
    }

    /// A plugin reset sets the service's S3 client to nil while a closure can still hold the service (#4426).
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service has been reset
    /// - When:
    ///    - createMultipartUpload is invoked
    /// - Then:
    ///    - a StorageError is thrown, and nothing is sent or reported to the session
    ///
    func testCreateMultipartUpload_afterServiceReset_shouldThrowStorageError() throws {
        serviceProxy.awsS3 = nil
        let error = try errorThrown { try self.client.createMultipartUpload() }
        XCTAssertTrue(error is StorageError)
        XCTAssertEqual(awss3Behavior.createMultipartUploadCount, 0)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
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
                    size: 1_024
                ),
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
    /// Then: A StorageError is thrown, and no part is prepared
    func testUploadPart_withoutServiceProxy_shouldThrowStorageError() throws {
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        serviceProxy = nil
        let error = try errorThrown {
            try client.uploadPart(
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
        XCTAssertTrue(error is StorageError)
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 0)
    }

    /// A plugin reset sets the service's presigner to nil while a part is being prepared (#4426).
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service has been reset after a part was queued
    /// - When:
    ///    - the part's partial file is ready and the part is presigned
    /// - Then:
    ///    - the failure is reported to the session once, instead of a fatal error
    ///
    func testUploadPart_afterServiceReset_shouldReportFailure() async throws {
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        client.integrate(session: session)
        try client.uploadPart(
            partNumber: 1,
            multipartUpload: .parts(
                uploadId: "uploadId",
                uploadFile: uploadFile,
                partSize: .default,
                parts: [.pending(bytes: 10)]
            ),
            subTask: .init(transferType: .multiPartUploadPart(uploadId: "uploadId", partNumber: 1), bucket: "bucket", key: "key")
        )
        serviceProxy.preSignedURLBuilder = nil
        session.failExpectation = expectation(description: "Part failure reported")

        fileSystem.releaseNextHeldRequest()

        await fulfillment(of: [session.failExpectation!], timeout: 1)
        XCTAssertEqual(session.failCount, 1)
        XCTAssertTrue(session.lastError is StorageError)
        XCTAssertEqual(session.handleUploadPartCount, 0)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: uploadPart is invoked with a snapshot that has no parts (e.g. the session is already aborting)
    /// Then: No part is started, and nothing is thrown or trapped
    func testUploadPart_withoutParts_shouldNotStartPart() throws {
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        let error = try errorThrown {
            try client.uploadPart(
                partNumber: 1,
                multipartUpload: .aborting(uploadId: "uploadId", error: nil),
                subTask: .init(
                    transferType: .upload(onEvent: { _ in }),
                    bucket: "bucket",
                    key: "key"
                )
            )
        }
        XCTAssertNil(error)
        // createPartialFile is the first, synchronous step of starting a part; `.started` is only reported later.
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 0)
    }

    /// The snapshot guard runs before the service guard: a part the session no longer needs must not fail it.
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service proxy has been released
    /// - When:
    ///    - uploadPart is invoked with a snapshot that has no parts, as when the session is already aborting
    /// - Then:
    ///    - nothing is thrown or trapped, and no part is prepared
    ///
    func testUploadPart_withoutPartsOrServiceProxy_shouldNotThrow() throws {
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        serviceProxy = nil
        let error = try errorThrown {
            try client.uploadPart(
                partNumber: 1,
                multipartUpload: .aborting(uploadId: "uploadId", error: nil),
                subTask: .init(transferType: .upload(onEvent: { _ in }), bucket: "bucket", key: "key")
            )
        }
        XCTAssertNil(error)
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 0)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: uploadPart is invoked with a part number outside the snapshot's parts, below and above
    /// Then: A StorageError is thrown each time, and no part is prepared
    func testUploadPart_withOutOfRangePartNumber_shouldThrowStorageError() throws {
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: serviceProxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: uploadFile
        )
        for partNumber in [0, 2] {
            let error = try errorThrown {
                try client.uploadPart(
                    partNumber: partNumber,
                    multipartUpload: .parts(
                        uploadId: "uploadId",
                        uploadFile: self.uploadFile,
                        partSize: .default,
                        parts: [.pending(bytes: 10)]
                    ),
                    subTask: .init(
                        transferType: .upload(onEvent: { _ in }),
                        bucket: "bucket",
                        key: "key"
                    )
                )
            }
            XCTAssertTrue(error is StorageError, "part \(partNumber)")
        }
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 0)
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
    /// Then: A StorageError is thrown, and nothing is sent or reported to the session
    func testCompleteMultipartUpload_withoutServiceProxy_shouldThrowStorageError() throws {
        serviceProxy = nil
        let error = try errorThrown { try self.client.completeMultipartUpload(uploadId: "uploadId") }
        XCTAssertTrue(error is StorageError)
        XCTAssertEqual(awss3Behavior.completeMultipartUploadCount, 0)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
        XCTAssertEqual(session.failCount, 0)
    }

    /// A plugin reset sets the service's S3 client to nil while a closure can still hold the service (#4426).
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service has been reset
    /// - When:
    ///    - completeMultipartUpload is invoked
    /// - Then:
    ///    - a StorageError is thrown, and nothing is sent or reported to the session
    ///
    func testCompleteMultipartUpload_afterServiceReset_shouldThrowStorageError() throws {
        serviceProxy.awsS3 = nil
        let error = try errorThrown { try self.client.completeMultipartUpload(uploadId: "uploadId") }
        XCTAssertTrue(error is StorageError)
        XCTAssertEqual(awss3Behavior.completeMultipartUploadCount, 0)
        XCTAssertEqual(session.handleMultipartUploadCount, 0)
        XCTAssertEqual(session.failCount, 0)
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
    /// Then: Nothing is thrown or sent, and an .aborted event is reported to the session, as S3's response would be
    func testAbortMultipartUpload_withoutServiceProxy_shouldReportAborted() async throws {
        serviceProxy = nil
        session.handleMultipartUploadExpectation = expectation(description: "Aborted reported")
        let error = try errorThrown { try self.client.abortMultipartUpload(uploadId: "uploadId") }
        XCTAssertNil(error)

        await fulfillment(of: [session.handleMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.abortMultipartUploadCount, 0)
        XCTAssertEqual(session.handleMultipartUploadCount, 1)
        XCTAssertEqual(session.failCount, 0)
        guard case .aborted(let uploadId, let abortError) = try XCTUnwrap(session.lastMultipartUploadEvent) else {
            return XCTFail("Expected .aborted, got \(String(describing: session.lastMultipartUploadEvent))")
        }
        XCTAssertEqual(uploadId, "uploadId")
        XCTAssertTrue(abortError is StorageError)
    }

    /// A plugin reset sets the service's S3 client to nil while a closure can still hold the service (#4426).
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service has been reset
    /// - When:
    ///    - abortMultipartUpload is invoked with an error
    /// - Then:
    ///    - nothing is thrown or sent, and an .aborted event carrying that error is reported to the session
    ///
    func testAbortMultipartUpload_afterServiceReset_shouldReportAborted() async throws {
        serviceProxy.awsS3 = nil
        session.handleMultipartUploadExpectation = expectation(description: "Aborted reported")
        let error = try errorThrown { try self.client.abortMultipartUpload(uploadId: "uploadId", error: CancellationError()) }
        XCTAssertNil(error)

        await fulfillment(of: [session.handleMultipartUploadExpectation!], timeout: 1)
        XCTAssertEqual(awss3Behavior.abortMultipartUploadCount, 0)
        XCTAssertEqual(session.failCount, 0)
        guard case .aborted(_, let abortError) = try XCTUnwrap(session.lastMultipartUploadEvent) else {
            return XCTFail("Expected .aborted, got \(String(describing: session.lastMultipartUploadEvent))")
        }
        XCTAssertTrue(abortError is CancellationError)
    }

    /// Without a session there is nothing to report to, so the client throws instead of trapping (#4426).
    ///
    /// - Given: DefaultStorageMultipartUploadClients with a live service proxy and no session: one never integrated,
    ///   one whose session was integrated and has since been deallocated
    /// - When:
    ///    - createMultipartUpload, completeMultipartUpload and abortMultipartUpload are invoked on each
    /// - Then:
    ///    - each throws a StorageError, and nothing is sent
    ///
    func testClientCalls_withoutSession_shouldThrowStorageError() throws {
        let neverIntegrated = DefaultStorageMultipartUploadClient(serviceProxy: serviceProxy, bucket: "bucket", key: "key", uploadFile: uploadFile)
        let sessionReleased = try makeClientWithReleasedSession()
        for concreteClient in [neverIntegrated, sessionReleased] {
            XCTAssertNil(concreteClient.session, "precondition: the client has no session")
            let client: StorageMultipartUploadClient = concreteClient
            let calls: [(name: String, call: () throws -> Void)] = [
                ("createMultipartUpload", { try client.createMultipartUpload() }),
                ("completeMultipartUpload", { try client.completeMultipartUpload(uploadId: "uploadId") }),
                ("abortMultipartUpload", { try client.abortMultipartUpload(uploadId: "uploadId") })
            ]
            for (name, call) in calls {
                let error = try errorThrown(by: call)
                XCTAssertTrue(error is StorageError, name)
            }
        }
        XCTAssertEqual(awss3Behavior.createMultipartUploadCount, 0)
        XCTAssertEqual(awss3Behavior.completeMultipartUploadCount, 0)
        XCTAssertEqual(awss3Behavior.abortMultipartUploadCount, 0)
    }

    /// Given: a DefaultStorageMultipartUploadClient
    /// When: cancelUploadTasks is invoked with identifiers
    /// Then: The tasks are unregistered
    func testCancelUploadTasks_shouldSucceed() async throws {
        let cancelExpectation = expectation(description: "Cancel Upload Tasks")
        client.cancelUploadTasks(taskIdentifiers: [0, 1, 2], done: {
            cancelExpectation.fulfill()
        })

        await fulfillment(of: [cancelExpectation], timeout: 1)
        XCTAssertEqual(serviceProxy.unregisterTaskIdentifiersCount, 1)
    }

    /// pause() waits for `done`, and without a service it was never called (#4426).
    ///
    /// - Given: a DefaultStorageMultipartUploadClient whose service proxy has been released
    /// - When:
    ///    - cancelUploadTasks is invoked
    /// - Then:
    ///    - `done` is still called
    ///
    func testCancelUploadTasks_withoutServiceProxy_shouldCallDone() async throws {
        serviceProxy = nil
        let cancelExpectation = expectation(description: "Cancel Upload Tasks")
        client.cancelUploadTasks(taskIdentifiers: [0, 1, 2], done: {
            cancelExpectation.fulfill()
        })

        await fulfillment(of: [cancelExpectation], timeout: 1)
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

    /// Regression test for #4407: cancel() racing the CreateMultipartUpload response handling. Before the fix
    /// this hit `fatalError("Part number is required")`.
    ///
    /// - Given: a real StorageMultipartUploadSession and DefaultStorageMultipartUploadClient for a 3-part upload,
    ///   with AbortMultipartUpload left in flight (completion never delivered, as on a real network)
    /// - When:
    ///    - this thread handles `.created` (S3's CreateMultipartUpload response)
    ///    - while another thread calls `cancel()` once `uploadParts` has queued a part, like an app watchdog
    ///      firing on a background wake
    /// - Then:
    ///    - `uploadPart` skips parts once the session has left `.parts`, instead of crashing or failing the upload
    ///
    func testCancelRacingCreatedResponse_shouldNotHitFatalError() throws {
        let size = UInt64(Bytes.megabytes(15).bytes)
        let bigFile = UploadFile(fileURL: uploadFile.fileURL, temporaryFileCreated: false, size: size)

        for iteration in 1 ... 100 {
            let awsS3 = MockAWSS3Behavior()
            let proxy = MockStorageServiceProxy(awsS3: awsS3)
            let client = DefaultStorageMultipartUploadClient(
                serviceProxy: proxy,
                fileSystem: HoldingPartialFileSystem(),
                bucket: "bucket",
                key: "key",
                uploadFile: bigFile
            )
            let failures = AtomicValue(initialValue: 0)
            let session = StorageMultipartUploadSession(client: client, bucket: "bucket", key: "key", onEvent: { event in
                if case .failed = event {
                    _ = failures.increment()
                }
            })
            session.handle(multipartUploadEvent: .creating)

            let stop = AtomicValue(initialValue: false)
            let started = DispatchSemaphore(value: 0)
            let cancellerDone = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                started.signal()
                // Cancel once uploadParts has queued a part, before it snapshots the state for each part.
                while session.part(for: 1)?.isQueued != true, !stop.get() {}
                if !stop.get() {
                    session.cancel()
                }
                cancellerDone.signal()
            }
            started.wait()
            // Runs on throw too: XCTAssertNoThrowFatalError throws XCTSkip on tvOS, watchOS and visionOS.
            defer {
                stop.set(true)
                // The client holds the proxy weakly; keep it alive until the canceller's abort() returns.
                cancellerDone.wait()
                withExtendedLifetime(proxy) {}
            }

            var finished = false
            try XCTAssertNoThrowFatalError {
                session.handle(multipartUploadEvent: .created(uploadFile: bigFile, uploadId: "uploadId"))
                finished = true
            }
            if !finished {
                XCTFail("fatalError(\"Part number is required\") hit on iteration \(iteration)")
                return
            }
            // A part skipped by uploadPart must not fail the upload: the abort still in flight owns the outcome.
            XCTAssertEqual(failures.get(), 0, "upload failed on iteration \(iteration)")
        }
    }

    /// Regression test for #4407 item G: a pause while parts are being prepared (partial file and presign).
    ///
    /// - Given: a real StorageMultipartUploadSession and DefaultStorageMultipartUploadClient for a 3-part upload,
    ///   with the partial-file copies held back so every part stays `.queued`
    /// - When:
    ///    - the upload is paused
    ///    - the partial files become ready while it is paused
    ///    - the upload is resumed
    /// - Then:
    ///    - no part request is sent while paused: each part's task is unregistered and cancelled instead
    ///    - each part returns to `.pending`
    ///    - resuming prepares all three parts again
    ///
    func testPauseWhilePartsArePrepared_shouldRestartThemOnResume() async throws {
        let size = UInt64(Bytes.megabytes(15).bytes)
        let bigFile = UploadFile(fileURL: uploadFile.fileURL, temporaryFileCreated: false, size: size)
        let proxy = MockStorageServiceProxy(awsS3: MockAWSS3Behavior())
        let fileSystem = HoldingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: proxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: bigFile
        )
        let session = StorageMultipartUploadSession(client: client, bucket: "bucket", key: "key", onEvent: { _ in })
        session.handle(multipartUploadEvent: .creating)
        session.handle(multipartUploadEvent: .created(uploadFile: bigFile, uploadId: "uploadId"))
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 3)

        session.pause()

        // One at a time: MockAWSS3PreSignedURLBuilder isn't safe for concurrent presigns.
        for partNumber in 1 ... 3 {
            let unregistered = expectation(description: "Part \(partNumber) is unregistered instead of sent")
            proxy.unregisterTaskExpectation = unregistered
            fileSystem.releaseNextHeldRequest()
            await fulfillment(of: [unregistered], timeout: 1)
        }
        XCTAssertEqual(session.getPendingPartNumbers(), [1, 2, 3])

        session.resume()
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 6)
    }

    /// Regression test for #4407 item G's narrower window: a `.started` handled between pause()'s transition and its
    /// reset of in-progress parts, which rebuilt the parts from the older snapshot and so undid the `.pending`.
    ///
    /// - Given: a 3-part upload with every part being prepared
    /// - When:
    ///    - another thread reports part 1 as started as soon as the upload is paused
    ///    - the upload is resumed
    /// - Then:
    ///    - part 1 is prepared again
    ///
    func testStartedWhilePausing_shouldRestartPartOnResume() throws {
        for iteration in 1 ... 1_000 {
            let proxy = MockStorageServiceProxy(awsS3: MockAWSS3Behavior())
            let fileSystem = HoldingPartialFileSystem()
            let session = makeThreePartSession(proxy: proxy, fileSystem: fileSystem)
            let delivered = DispatchSemaphore(value: 0)
            DispatchQueue.global(qos: .userInitiated).async {
                while !session.isPaused {}
                // What startUploadPart reports once part 1's partial file and URL are ready.
                session.handle(uploadPartEvent: .started(partNumber: 1, taskIdentifier: 1))
                delivered.signal()
            }
            session.pause()
            delivered.wait()
            session.resume()
            withExtendedLifetime(proxy) {}
            // Parts 2 and 3 are still being prepared, so only part 1 is prepared again.
            guard fileSystem.createPartialFileCount.get() == 4 else {
                XCTFail("Part 1 was not restarted after resume on iteration \(iteration)")
                return
            }
        }
    }

    /// Regression test for a deadlock in pause(): it waited for URLSession's task list while holding the session's
    /// lock, but URLSession delivers that list on its delegate queue, behind delegate callbacks that wait for the lock.
    ///
    /// - Given: a 3-part upload with part 1 in progress, on a URLSession whose delegate queue is about to report
    ///   part 1's progress
    /// - When:
    ///    - the upload is paused before that callback runs
    /// - Then:
    ///    - pause() returns
    ///
    func testPauseWhileDelegateReportsProgress_shouldNotDeadlock() async throws {
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        let proxy = MockStorageServiceProxy(awsS3: MockAWSS3Behavior())
        proxy.urlSession = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: delegateQueue)
        let session = makeThreePartSession(proxy: proxy, fileSystem: HoldingPartialFileSystem())
        session.handle(uploadPartEvent: .started(partNumber: 1, taskIdentifier: 1))

        // A progress callback that runs once pause() has asked URLSession for its tasks.
        delegateQueue.addOperation {
            Thread.sleep(forTimeInterval: 0.2)
            session.handle(uploadPartEvent: .progressUpdated(partNumber: 1, bytesTransferred: 1, taskIdentifier: 1))
        }
        let paused = expectation(description: "pause() returned")
        DispatchQueue.global().async {
            session.pause()
            paused.fulfill()
        }
        await fulfillment(of: [paused], timeout: 3)
        withExtendedLifetime(proxy) {}
    }

    // MARK: - Released storage service (#4426)

    /// Regression test for #4426, the reporter's stack: AWSS3StorageUploadFileOperation.cancel() cancels the task
    /// reference, and the session's abort() hit `fatalError()` in abortMultipartUpload because the storage service that
    /// started the upload had been deallocated.
    ///
    /// - Given: a 3-part upload started through a real StorageMultipartUploadSession and
    ///   DefaultStorageMultipartUploadClient, whose service proxy has since been released
    /// - When:
    ///    - the task reference reported in `.initiated` is cancelled, as AWSS3StorageUploadFileOperation.cancel() does
    /// - Then:
    ///    - no fatal error is hit and AbortMultipartUpload is not sent
    ///    - the session ends aborted, and the caller is told `.initiated` and then `.failed`, once
    ///
    func testCancel_afterServiceProxyReleased_shouldAbortWithoutFatalError() async throws {
        let recorder = MultipartUploadEventRecorder()
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let upload = try makeStartedThreePartUpload(proxy: XCTUnwrap(proxy), awsS3: awsS3, recorder: recorder)
        let reference = try XCTUnwrap(recorder.initiatedReference)
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(upload.client.serviceProxy, "precondition: the service proxy is released")

        recorder.terminalExpectation = expectation(description: "Terminal event reported")
        try XCTAssertNoThrowFatalError {
            reference.cancel()
        }

        await fulfillment(of: [try XCTUnwrap(recorder.terminalExpectation)], timeout: 1)
        XCTAssertEqual(awsS3.abortMultipartUploadCount, 0)
        XCTAssertTrue(upload.session.isAborted)
        XCTAssertEqual(recorder.names, ["initiated", "failed"])
    }

    /// Regression test for #4426: the progress stall timeout aborting an upload whose storage service was deallocated
    /// hit the same `fatalError()`, on the stall timer's queue.
    ///
    /// - Given: a 3-part upload started through a real session and client, whose service proxy has been released
    /// - When:
    ///    - the session aborts with the progress stall timeout's error, as its stall timer does
    ///    - the app then cancels the upload
    /// - Then:
    ///    - no fatal error is hit and AbortMultipartUpload is not sent
    ///    - the caller is told `.failed` once, with the stall timeout as the underlying error
    ///    - the later cancel reports nothing more
    ///
    func testProgressStallAbort_afterServiceProxyReleased_shouldFailOnceWithStallError() async throws {
        let recorder = MultipartUploadEventRecorder()
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let upload = try makeStartedThreePartUpload(proxy: XCTUnwrap(proxy), awsS3: awsS3, recorder: recorder)
        let reference = try XCTUnwrap(recorder.initiatedReference)
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(upload.client.serviceProxy, "precondition: the service proxy is released")

        let stallError = StorageError.unknown("Upload cancelled due to progress stall timeout.", nil)
        recorder.terminalExpectation = expectation(description: "Terminal event reported")
        try XCTAssertNoThrowFatalError {
            upload.session.handle(multipartUploadEvent: .aborting(error: stallError))
        }
        await fulfillment(of: [try XCTUnwrap(recorder.terminalExpectation)], timeout: 1)

        let noFurtherEvent = expectation(description: "No further terminal event")
        noFurtherEvent.isInverted = true
        recorder.terminalExpectation = noFurtherEvent
        try XCTAssertNoThrowFatalError {
            reference.cancel()
        }
        await fulfillment(of: [noFurtherEvent], timeout: 0.5)

        XCTAssertEqual(awsS3.abortMultipartUploadCount, 0)
        XCTAssertEqual(recorder.terminalNames, ["failed"])
        guard case .unknown(_, let underlyingError) = try XCTUnwrap(recorder.failures.first),
              case .unknown(let description, _) = try XCTUnwrap(underlyingError as? StorageError) else {
            return XCTFail("Expected the stall timeout as the underlying error: \(recorder.failures)")
        }
        XCTAssertEqual(description, "Upload cancelled due to progress stall timeout.")
    }

    /// Regression test for #4426: resume() after the storage service was deallocated hit
    /// `fatalError("Service Proxy is required")` in uploadPart.
    ///
    /// - Given: a 3-part upload paused while its parts were in progress, whose service proxy has since been released
    /// - When:
    ///    - the upload is resumed
    /// - Then:
    ///    - no fatal error is hit and no part is prepared again
    ///    - the caller is told `.failed`, once
    ///
    func testResume_afterServiceProxyReleased_shouldFailWithoutFatalError() throws {
        let recorder = MultipartUploadEventRecorder()
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let upload = try makeStartedThreePartUpload(proxy: XCTUnwrap(proxy), awsS3: awsS3, recorder: recorder)
        for partNumber in 1 ... 3 {
            upload.session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: partNumber))
        }
        upload.session.pause()
        XCTAssertEqual(upload.session.getPendingPartNumbers(), [1, 2, 3], "precondition: pause() returned the parts to pending")
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(upload.client.serviceProxy, "precondition: the service proxy is released")

        try XCTAssertNoThrowFatalError {
            upload.session.resume()
        }

        XCTAssertEqual(upload.fileSystem.createPartialFileCount.get(), 3)
        XCTAssertEqual(recorder.terminalNames, ["failed"])
    }

    /// Regression test for a hang next to #4426's traps: with the storage service deallocated, cancelUploadTasks
    /// returned without calling `done`, so pause() waited forever.
    ///
    /// - Given: a 3-part upload with part 1 in progress, whose service proxy has been released
    /// - When:
    ///    - the upload is paused
    /// - Then:
    ///    - pause() returns, and the upload is paused without a terminal event
    ///
    func testPause_afterServiceProxyReleased_shouldNotHang() async throws {
        let recorder = MultipartUploadEventRecorder()
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let upload = try makeStartedThreePartUpload(proxy: XCTUnwrap(proxy), awsS3: awsS3, recorder: recorder)
        upload.session.handle(uploadPartEvent: .started(partNumber: 1, taskIdentifier: 1))
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(upload.client.serviceProxy, "precondition: the service proxy is released")

        let session = upload.session
        let paused = expectation(description: "pause() returned")
        DispatchQueue.global().async {
            session.pause()
            paused.fulfill()
        }

        await fulfillment(of: [paused], timeout: 2)
        XCTAssertTrue(session.isPaused)
        XCTAssertEqual(recorder.terminalNames, [])
    }

    /// #4426, defensive: createMultipartUpload no longer traps when the storage service was deallocated, though no
    /// production path calls it then.
    ///
    /// - Given: a real StorageMultipartUploadSession and DefaultStorageMultipartUploadClient whose service proxy has
    ///   been released
    /// - When:
    ///    - the upload is started
    /// - Then:
    ///    - no fatal error is hit and CreateMultipartUpload is not sent
    ///    - the caller is told `.initiated` and then `.failed`, once
    ///
    func testStartUpload_afterServiceProxyReleased_shouldFailWithoutFatalError() throws {
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let client = try DefaultStorageMultipartUploadClient(
            serviceProxy: XCTUnwrap(proxy),
            bucket: "bucket",
            key: "key",
            uploadFile: threePartFile
        )
        let recorder = MultipartUploadEventRecorder()
        let session = StorageMultipartUploadSession(client: client, bucket: "bucket", key: "key", onEvent: { recorder.record($0) })
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(client.serviceProxy, "precondition: the service proxy is released")

        try XCTAssertNoThrowFatalError {
            session.startUpload()
        }

        XCTAssertEqual(awsS3.createMultipartUploadCount, 0)
        XCTAssertEqual(recorder.names, ["initiated", "failed"])
    }

    /// #4426, defensive: completeMultipartUpload no longer traps when the storage service was deallocated, though no
    /// production path calls it then.
    ///
    /// - Given: a 3-part upload whose first two parts have completed, and whose service proxy has since been released
    /// - When:
    ///    - the last part completes
    /// - Then:
    ///    - no fatal error is hit and CompleteMultipartUpload is not sent
    ///    - after the three `.inProcess` updates the caller is told `.failed`, once
    ///
    func testLastPartCompleted_afterServiceProxyReleased_shouldFailWithoutFatalError() throws {
        let recorder = MultipartUploadEventRecorder()
        let awsS3 = MockAWSS3Behavior()
        var proxy: MockStorageServiceProxy? = MockStorageServiceProxy(awsS3: awsS3)
        let upload = try makeStartedThreePartUpload(proxy: XCTUnwrap(proxy), awsS3: awsS3, recorder: recorder)
        for partNumber in 1 ... 3 {
            upload.session.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: partNumber))
        }
        for partNumber in 1 ... 2 {
            upload.session.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: "eTag", taskIdentifier: partNumber))
        }
        withExtendedLifetime(proxy) {}
        proxy = nil
        XCTAssertNil(upload.client.serviceProxy, "precondition: the service proxy is released")

        try XCTAssertNoThrowFatalError {
            upload.session.handle(uploadPartEvent: .completed(partNumber: 3, eTag: "eTag", taskIdentifier: 3))
        }

        XCTAssertEqual(awsS3.completeMultipartUploadCount, 0)
        XCTAssertEqual(recorder.names, ["initiated", "inProcess", "inProcess", "inProcess", "failed"])
    }

    /// Runs `call`, failing the test if it hits a fatal error, and returns what it threw.
    private func errorThrown(
        file: StaticString = #filePath,
        line: UInt = #line,
        by call: @escaping () throws -> Void
    ) throws -> Error? {
        var thrownError: Error?
        try XCTAssertNoThrowFatalError({
            do {
                try call()
            } catch {
                thrownError = error
            }
        }, file: file, line: line)
        return thrownError
    }

    /// A client whose session was integrated and has since been deallocated. The session comes from the restore
    /// initializer: the one `AWSS3StorageService.multiPartUpload` creates is retained by its own transfer task.
    private func makeClientWithReleasedSession() throws -> DefaultStorageMultipartUploadClient {
        let client = DefaultStorageMultipartUploadClient(serviceProxy: serviceProxy, bucket: "bucket", key: "key", uploadFile: uploadFile)
        weak var releasedSession: StorageMultipartUploadSession?
        do {
            let transferTask = StorageTransferTask(
                transferType: .multiPartUpload(onEvent: { _ in }),
                bucket: "bucket",
                key: "key",
                storageTransferDatabase: MockStorageTransferDatabase()
            )
            let session = try XCTUnwrap(StorageMultipartUploadSession(client: client, transferTask: transferTask, multipartUpload: .none))
            client.integrate(session: session)
            releasedSession = session
        }
        XCTAssertNil(releasedSession, "precondition: the session is deallocated")
        return client
    }

    /// 15 MB, so three 5 MB parts.
    private var threePartFile: UploadFile {
        UploadFile(fileURL: uploadFile.fileURL, temporaryFileCreated: false, size: UInt64(Bytes.megabytes(15).bytes))
    }

    /// A 3-part upload started through a real session and client, in `.parts` with every part `.queued`. Partial-file
    /// requests are dropped, so once this returns only the caller keeps `proxy` alive.
    private func makeStartedThreePartUpload(
        proxy: MockStorageServiceProxy,
        awsS3: MockAWSS3Behavior,
        recorder: MultipartUploadEventRecorder
    ) -> (session: StorageMultipartUploadSession, client: DefaultStorageMultipartUploadClient, fileSystem: DiscardingPartialFileSystem) {
        awsS3.createMultipartUploadResult = .success(.init(bucket: "bucket", key: "key", uploadId: "uploadId"))
        let fileSystem = DiscardingPartialFileSystem()
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: proxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: threePartFile
        )
        let session = StorageMultipartUploadSession(client: client, bucket: "bucket", key: "key", onEvent: { recorder.record($0) })
        session.startUpload()
        XCTAssertEqual(fileSystem.createPartialFileCount.get(), 3, "precondition: every part is being prepared")
        return (session, client, fileSystem)
    }

    /// A real session and client for a 3-part upload, with every part `.queued` behind `fileSystem`.
    private func makeThreePartSession(
        proxy: MockStorageServiceProxy,
        fileSystem: HoldingPartialFileSystem
    ) -> StorageMultipartUploadSession {
        let size = UInt64(Bytes.megabytes(15).bytes)
        let bigFile = UploadFile(fileURL: uploadFile.fileURL, temporaryFileCreated: false, size: size)
        let client = DefaultStorageMultipartUploadClient(
            serviceProxy: proxy,
            fileSystem: fileSystem,
            bucket: "bucket",
            key: "key",
            uploadFile: bigFile
        )
        let session = StorageMultipartUploadSession(client: client, bucket: "bucket", key: "key", onEvent: { _ in })
        session.handle(multipartUploadEvent: .creating)
        session.handle(multipartUploadEvent: .created(uploadFile: bigFile, uploadId: "uploadId"))
        return session
    }
}

/// Counts partial-file requests and holds them until `releaseNextHeldRequest()`, so parts stay `.queued` and
/// touch neither disk nor network.
private final class HoldingPartialFileSystem: FileSystem, @unchecked Sendable {
    let createPartialFileCount = AtomicValue(initialValue: 0)
    private let heldRequests = AtomicValue<[@Sendable (Result<URL, Error>) -> Void]>(initialValue: [])

    override func createPartialFile(fileURL: URL, offset: UInt64, length: UInt64, completionHandler: @escaping @Sendable (Result<URL, Error>) -> Void) {
        _ = createPartialFileCount.increment()
        heldRequests.append(completionHandler)
    }

    /// Completes the oldest held request with a file that doesn't exist, as the client deletes it after use.
    func releaseNextHeldRequest() {
        var held = heldRequests.get()
        guard !held.isEmpty else { return }
        let completion = held.removeFirst()
        heldRequests.set(held)
        completion(.success(FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)))
    }
}

/// Counts partial-file requests and drops them, so parts stay `.queued` and nothing else keeps the service proxy alive.
private final class DiscardingPartialFileSystem: FileSystem, @unchecked Sendable {
    let createPartialFileCount = AtomicValue(initialValue: 0)

    override func createPartialFile(fileURL: URL, offset: UInt64, length: UInt64, completionHandler: @escaping @Sendable (Result<URL, Error>) -> Void) {
        _ = createPartialFileCount.increment()
    }
}

/// Records what a session reports through `onEvent`.
private final class MultipartUploadEventRecorder: @unchecked Sendable {
    private let events = AtomicValue<[AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEvent]>(initialValue: [])
    /// Fulfilled by each `.completed` or `.failed`.
    var terminalExpectation: XCTestExpectation?

    func record(_ event: AWSS3StorageServiceBehavior.StorageServiceMultiPartUploadEvent) {
        events.append(event)
        switch event {
        case .completed, .failed:
            terminalExpectation?.fulfill()
        case .initiated, .inProcess:
            break
        }
    }

    /// Each event's case, in the order reported.
    var names: [String] {
        events.get().map { event in
            switch event {
            case .initiated: "initiated"
            case .inProcess: "inProcess"
            case .completed: "completed"
            case .failed: "failed"
            }
        }
    }

    var terminalNames: [String] {
        names.filter { $0 == "completed" || $0 == "failed" }
    }

    var failures: [StorageError] {
        events.get().compactMap { event in
            guard case .failed(let error) = event else { return nil }
            return error
        }
    }

    /// The reference from `.initiated`, which AWSS3StorageUploadFileOperation keeps and cancels.
    var initiatedReference: StorageTaskReference? {
        for case .initiated(let reference) in events.get() {
            return reference
        }
        return nil
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

private class MockStorageServiceProxy: StorageServiceProxy, @unchecked Sendable {
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior! = MockAWSS3PreSignedURLBuilder()
    var awsS3: AWSS3Behavior!
    var urlSession = URLSession.shared
    var userAgent: String = ""
    var urlRequestDelegate: URLRequestDelegate?

    init(awsS3: AWSS3Behavior) {
        self.awsS3 = awsS3
    }

    func register(task: StorageTransferTask) {}

    var unregisterTaskExpectation: XCTestExpectation?
    func unregister(task: StorageTransferTask) {
        unregisterTaskExpectation?.fulfill()
    }

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
    var createMultipartUploadResult: Result<AWSS3CreateMultipartUploadResponse, StorageError>?
    var createMultipartUploadExpectation: XCTestExpectation?
    func createMultipartUpload(_ request: CreateMultipartUploadRequest, completion: @escaping (Result<AWSS3CreateMultipartUploadResponse, StorageError>) -> Void) {
        createMultipartUploadCount += 1
        if let result = createMultipartUploadResult {
            completion(result)
        }
        createMultipartUploadExpectation?.fulfill()
    }

    var completeMultipartUploadCount = 0
    var completeMultipartUploadResult: Result<AWSS3CompleteMultipartUploadResponse, StorageError>?
    var completeMultipartUploadExpectation: XCTestExpectation?
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest, completion: @escaping (Result<AWSS3CompleteMultipartUploadResponse, StorageError>) -> Void) {
        completeMultipartUploadCount += 1
        if let result = completeMultipartUploadResult {
            completion(result)
        }
        completeMultipartUploadExpectation?.fulfill()
    }

    var abortMultipartUploadCount = 0
    var abortMultipartUploadResult: Result<Void, StorageError>?
    var abortMultipartUploadExpectation: XCTestExpectation?
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

class MockStorageMultipartUploadSession: StorageMultipartUploadSession, @unchecked Sendable {
    var handleMultipartUploadCount = 0
    var lastMultipartUploadEvent: StorageMultipartUploadEvent?
    var handleMultipartUploadExpectation: XCTestExpectation?
    override func handle(multipartUploadEvent: StorageMultipartUploadEvent) {
        handleMultipartUploadCount += 1
        lastMultipartUploadEvent = multipartUploadEvent
        handleMultipartUploadExpectation?.fulfill()
    }

    var handleUploadPartCount = 0
    var lastUploadEvent: StorageUploadPartEvent?
    var handleUploadPartExpectation: XCTestExpectation?

    override func handle(uploadPartEvent: StorageUploadPartEvent) {
        handleUploadPartCount += 1
        lastUploadEvent = uploadPartEvent
        handleUploadPartExpectation?.fulfill()
    }

    var failCount = 0
    var lastError: Error?
    var failExpectation: XCTestExpectation?
    override func fail(error: Error) {
        failCount += 1
        lastError = error
        failExpectation?.fulfill()
    }
}
