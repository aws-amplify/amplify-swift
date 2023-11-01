//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSS3StoragePlugin
import XCTest

class AWSS3AdapterTests: XCTestCase {
    private var adapter: AWSS3Adapter!
    private var awsS3: S3ClientMock!

    override func setUp() async throws {
        awsS3 = S3ClientMock()
        adapter = AWSS3Adapter(awsS3)
    }

    override func tearDown() async throws {
        adapter = nil
        awsS3 = nil
    }

    /// Given: An AWSS3Adapter
    /// When: deleteObject is invoked and the s3 client returns success
    /// Then: A .success result is returned
    func testDeleteObject_withSuccess_shouldSucceed() async throws {
        let deleteExpectation = expectation(description: "Delete Object")
        try await adapter.deleteObject(.init(bucket: "bucket", key: "key"))
        XCTAssertEqual(self.awsS3.deleteObjectCount, 1)
    }

    /// Given: An AWSS3Adapter
    /// When: deleteObject is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testDeleteObject_withError_shouldFail() async throws {
        let deleteExpectation = expectation(description: "Delete Object")
        awsS3.deleteObjectResult = .failure(StorageError.keyNotFound("InvalidKey", "", "", nil))
        do {
            try await adapter.deleteObject(.init(bucket: "bucket", key: "key"))
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(self.awsS3.deleteObjectCount, 1)
            guard case .keyNotFound(let key, _, _, _) = (error as? StorageError) else {
                XCTFail("Expected StorageError.keyNotFound")
                return
            }
            XCTAssertEqual(key, "InvalidKey")
        }
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns a list of objects
    /// Then: A .success result is returned containing the corresponding list items
    func testListObjectsV2_withSuccess_shouldSucceed() async throws {
        let listExpectation = expectation(description: "List Objects")
        awsS3.listObjectsV2Result = .success(ListObjectsV2OutputResponse(
            contents: [
                .init(eTag: "one", key: "prefix/key1", lastModified: .init()),
                .init(eTag: "two", key: "prefix/key2", lastModified: .init())
            ]
        ))
        let response = try await adapter.listObjectsV2(
            .init(
                bucket: "bucket",
                prefix: "prefix/"
            )
        )
        XCTAssertEqual(self.awsS3.listObjectsV2Count, 1)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertTrue(response.items.contains(where: { $0.key == "key1" && $0.eTag == "one" }))
        XCTAssertTrue(response.items.contains(where: { $0.key == "key2" && $0.eTag == "two" }))
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListObjectsV2_withError_shouldFail() async throws {
        let listExpectation = expectation(description: "List Objects")
        awsS3.listObjectsV2Result = .failure(StorageError.accessDenied("AccessDenied", "", nil))
        
        do {
            _ = try await adapter.listObjectsV2(
                .init(
                    bucket: "bucket",
                    prefix: "prefix"
                )
            )
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(self.awsS3.listObjectsV2Count, 1)
            guard case .accessDenied(let description, _, _) = error as? StorageError else {
                XCTFail("Expected StorageError.accessDenied")
                return
            }
            XCTAssertEqual(description, "AccessDenied")
        }
    }
    
    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCreateMultipartUpload_withSuccess_shouldSucceed() async throws {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awsS3.createMultipartUploadResult = .success(.init(
            bucket: "bucket",
            key: "key",
            uploadId: "uploadId"
        ))
        let response = try await adapter.createMultipartUpload(.init(bucket: "bucket", key: "key"))
        XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
        XCTAssertEqual(response.bucket, "bucket")
        XCTAssertEqual(response.key, "key")
        XCTAssertEqual(response.uploadId, "uploadId")
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .uknown error
    func testCreateMultipartUpload_withWrongResponse_shouldFail() async throws {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        
        do {
           _ = try await adapter.createMultipartUpload(.init(bucket: "bucket", key: "key"))
        } catch {
            XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
            guard case .unknown(let description, _) = error as? StorageError else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "Invalid response for creating multipart upload")
        }
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCreateMultipartUpload_withError_shouldFail() async throws {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awsS3.createMultipartUploadResult = .failure(StorageError.accessDenied("AccessDenied", "", nil))

        do {
            _ = try await adapter.createMultipartUpload(.init(bucket: "bucket", key: "key"))
        } catch {
            XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
            guard case .accessDenied(let description, _, _) = error as? StorageError else {
                XCTFail("Expected StorageError.accessDenied")
                return
            }
            XCTAssertEqual(description, "AccessDenied")
        }
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testListParts_withSuccess_shouldSucceed() async throws {
        awsS3.listPartsResult = .success(.init(
            bucket: "bucket",
            key: "key",
            parts: [
                .init(eTag: "eTag1", partNumber: 1),
                .init(eTag: "eTag2", partNumber: 2)
            ],
            uploadId: "uploadId"
        ))
        let response = try await adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId")
        XCTAssertEqual(self.awsS3.listPartsCount, 1)
        XCTAssertEqual(response.bucket, "bucket")
        XCTAssertEqual(response.key, "key")
        XCTAssertEqual(response.uploadId, "uploadId")
        XCTAssertEqual(response.parts.count, 2)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .unknown error
    func testListParts_withWrongResponse_shouldFail() async throws {
        do {
            _ = try await adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId")
        } catch {
            XCTAssertEqual(self.awsS3.listPartsCount, 1)
            guard case .unknown(let description, _) = error as? StorageError else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "ListParts response is invalid")
        }
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListParts_withError_shouldFail() async throws {
        awsS3.listPartsResult = .failure(StorageError.authError("AuthError", "", nil))

        do {
            _ = try await adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId")
        } catch {
            XCTAssertEqual(self.awsS3.listPartsCount, 1)
            guard case .authError(let description, _, _) = error as? StorageError else {
                XCTFail("Expected StorageError.authError")
                return
            }
            XCTAssertEqual(description, "ListParts response is invalid")
        }
    }
    
    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCompleteMultipartUpload_withSuccess_shouldSucceed() async throws {
        awsS3.completeMultipartUploadResult = .success(.init(
            eTag: "eTag"
        ))
        
        let response = try await adapter.completeMultipartUpload(
            .init(
                bucket: "bucket",
                key: "key",
                uploadId: "uploadId",
                parts: [.init(partNumber: 1, eTag: "eTag1"), .init(partNumber: 2, eTag: "eTag2")]
            )
        )
        XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
        XCTAssertEqual(response.bucket, "bucket")
        XCTAssertEqual(response.key, "key")
        XCTAssertEqual(response.eTag, "eTag")
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with .unknown error
    func testCompleteMultipartUpload_withWrongResponse_shouldFail() async throws {
        do {
            _ = try await adapter.completeMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId", parts: []))
            XCTFail("...")
        } catch {
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .unknown(let description, _) = error as? StorageError else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "Invalid response for completing multipart upload")
        }
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCompleteMultipartUpload_withError_shouldFail() async throws {
        awsS3.completeMultipartUploadResult = .failure(StorageError.authError("AuthError", "", nil))

        do {
            _ = try await adapter.completeMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId", parts: []))
            XCTFail("...")
        } catch {
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .authError(let description, _, _) = error as? StorageError else {
                XCTFail("Expected StorageError.authError")
                return
            }
            XCTAssertEqual(description, "AuthError")
        }
    }
    
    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned
    func testAbortMultipartUpload_withSuccess_shouldSucceed() async throws {
        let abortExpectation = expectation(description: "Abort Multipart Upload")
        _ = try await adapter.abortMultipartUpload(
            .init(bucket: "bucket", key: "key", uploadId: "uploadId")
        )
        XCTAssertEqual(self.awsS3.abortMultipartUploadCount, 1)
    }

    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testAbortMultipartUpload_withError_shouldFail() async throws {
        let abortExpectation = expectation(description: "Abort Multipart Upload")
        awsS3.abortMultipartUploadResult = .failure(StorageError.keyNotFound("InvalidKey", "", "", nil))
        
        do {
            _ = try await adapter.completeMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId", parts: []))
            XCTFail("...")
        } catch {
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .keyNotFound(let key, _, _, _) = error as? StorageError else {
                XCTFail("Expected StorageError.keyNotFound")
                return
            }
            XCTAssertEqual(key, "InvalidKey")
        }
    }
}

private class S3ClientMock: S3ClientProtocol {
    var headObjectCount = 0
    var headObjectResult: Result<HeadObjectOutputResponse, Error> = .success(.init())
    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse {
        headObjectCount += 1
        return try headObjectResult.get()
    }
    
    var deleteObjectCount = 0
    var deleteObjectResult: Result<DeleteObjectOutputResponse, Error> = .success(.init())
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse {
        deleteObjectCount += 1
        return try deleteObjectResult.get()
    }
    
    var listObjectsV2Count = 0
    var listObjectsV2Result: Result<ListObjectsV2OutputResponse, Error> = .success(.init())
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse {
        listObjectsV2Count += 1
        return try listObjectsV2Result.get()
    }
    
    var createMultipartUploadCount = 0
    var createMultipartUploadResult: Result<CreateMultipartUploadOutputResponse, Error> = .success(.init())
    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse {
        createMultipartUploadCount += 1
        return try createMultipartUploadResult.get()
    }
    
    var listPartsCount = 0
    var listPartsResult: Result<ListPartsOutputResponse, Error> = .success(.init())
    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse {
        listPartsCount += 1
        return try listPartsResult.get()
    }
    
    var completeMultipartUploadCount = 0
    var completeMultipartUploadResult: Result<CompleteMultipartUploadOutputResponse, Error> = .success(.init())
    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse {
        completeMultipartUploadCount += 1
        return try completeMultipartUploadResult.get()
    }
    
    var abortMultipartUploadCount = 0
    var abortMultipartUploadResult: Result<AbortMultipartUploadOutputResponse, Error> = .success(.init())
    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse {
        abortMultipartUploadCount += 1
        return try abortMultipartUploadResult.get()
    }
}
