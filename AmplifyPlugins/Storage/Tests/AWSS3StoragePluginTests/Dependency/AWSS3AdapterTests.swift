//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSS3StoragePlugin
import AWSS3
import XCTest

class AWSS3AdapterTests: XCTestCase {
    private var adapter: AWSS3Adapter!
    private var awsS3: S3ClientMock!

    override func setUp() {
        awsS3 = S3ClientMock()
        adapter = AWSS3Adapter(
            awsS3,
            config: try! S3Client.S3ClientConfiguration(
                region: "us-east-1"
            )
        )
    }

    override func tearDown() {
        adapter = nil
        awsS3 = nil
    }

    /// Given: An AWSS3Adapter
    /// When: deleteObject is invoked and the s3 client returns success
    /// Then: A .success result is returned
    func testDeleteObject_withSuccess_shouldSucceed() {
        let deleteExpectation = expectation(description: "Delete Object")
        adapter.deleteObject(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.deleteObjectCount, 1)
            guard case .success = result else {
                XCTFail("Expected success")
                return
            }
            deleteExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: deleteObject is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testDeleteObject_withError_shouldFail() {
        let deleteExpectation = expectation(description: "Delete Object")
        awsS3.deleteObjectResult = .failure(StorageError.keyNotFound("InvalidKey", "", "", nil))
        adapter.deleteObject(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.deleteObjectCount, 1)
            guard case .failure(let error) = result,
                  case .keyNotFound(let key, _, _, _) = error else {
                XCTFail("Expected StorageError.keyNotFound")
                return
            }
            XCTAssertEqual(key, "InvalidKey")
            deleteExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns a list of objects
    /// Then: A .success result is returned containing the corresponding list items
    func testListObjectsV2_withSuccess_shouldSucceed() {
        let listExpectation = expectation(description: "List Objects")
        awsS3.listObjectsV2Result = .success(ListObjectsV2OutputResponse(
            contents: [
                .init(eTag: "one", key: "prefix/key1", lastModified: .init()),
                .init(eTag: "two", key: "prefix/key2", lastModified: .init())
            ]
        ))
        adapter.listObjectsV2(.init(
            bucket: "bucket",
            prefix: "prefix/"
        )) { result in
            XCTAssertEqual(self.awsS3.listObjectsV2Count, 1)
            guard case .success(let response) = result else {
                XCTFail("Expected success")
                return
            }
            XCTAssertEqual(response.items.count, 2)
            XCTAssertTrue(response.items.contains(where: { $0.key == "key1" && $0.eTag == "one" }))
            XCTAssertTrue(response.items.contains(where: { $0.key == "key2" && $0.eTag == "two" }))
            listExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListObjectsV2_withError_shouldFail() {
        let listExpectation = expectation(description: "List Objects")
        awsS3.listObjectsV2Result = .failure(StorageError.accessDenied("AccessDenied", "", nil))
        adapter.listObjectsV2(.init(
            bucket: "bucket",
            prefix: "prefix"
        )) { result in
            XCTAssertEqual(self.awsS3.listObjectsV2Count, 1)
            guard case .failure(let error) = result,
                  case .accessDenied(let description, _, _) = error else {
                XCTFail("Expected StorageError.accessDenied")
                return
            }
            XCTAssertEqual(description, "AccessDenied")
            listExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCreateMultipartUpload_withSuccess_shouldSucceed() {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awsS3.createMultipartUploadResult = .success(.init(
            bucket: "bucket",
            key: "key",
            uploadId: "uploadId"
        ))
        adapter.createMultipartUpload(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
            guard case .success(let response) = result else {
                XCTFail("Expected success")
                return
            }
            XCTAssertEqual(response.bucket, "bucket")
            XCTAssertEqual(response.key, "key")
            XCTAssertEqual(response.uploadId, "uploadId")
            createMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .uknown error
    func testCreateMultipartUpload_withWrongResponse_shouldFail() {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        adapter.createMultipartUpload(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
            guard case .failure(let error) = result,
                  case .unknown(let description, _) = error else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "Invalid response for creating multipart upload")
            createMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCreateMultipartUpload_withError_shouldFail() {
        let createMultipartUploadExpectation = expectation(description: "Create Multipart Upload")
        awsS3.createMultipartUploadResult = .failure(StorageError.accessDenied("AccessDenied", "", nil))
        adapter.createMultipartUpload(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.createMultipartUploadCount, 1)
            guard case .failure(let error) = result,
                  case .accessDenied(let description, _, _) = error else {
                XCTFail("Expected StorageError.accessDenied")
                return
            }
            XCTAssertEqual(description, "AccessDenied")
            createMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testListParts_withSuccess_shouldSucceed() {
        let listPartsExpectation = expectation(description: "List Parts")
        awsS3.listPartsResult = .success(.init(
            bucket: "bucket",
            key: "key",
            parts: [
                .init(eTag: "eTag1", partNumber: 1),
                .init(eTag: "eTag2", partNumber: 2)
            ],
            uploadId: "uploadId"
        ))
        adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId") { result in
            XCTAssertEqual(self.awsS3.listPartsCount, 1)
            guard case .success(let response) = result else {
                XCTFail("Expected success")
                return
            }
            XCTAssertEqual(response.bucket, "bucket")
            XCTAssertEqual(response.key, "key")
            XCTAssertEqual(response.uploadId, "uploadId")
            XCTAssertEqual(response.parts.count, 2)
            listPartsExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .unknown error
    func testListParts_withWrongResponse_shouldFail() {
        let listPartsExpectation = expectation(description: "List Parts")
        adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId") { result in
            XCTAssertEqual(self.awsS3.listPartsCount, 1)
            guard case .failure(let error) = result,
                  case .unknown(let description, _) = error else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "ListParts response is invalid")
            listPartsExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListParts_withError_shouldFail() {
        let listPartsExpectation = expectation(description: "List Parts")
        awsS3.listPartsResult = .failure(StorageError.authError("AuthError", "", nil))
        adapter.listParts(bucket: "bucket", key: "key", uploadId: "uploadId") { result in
            XCTAssertEqual(self.awsS3.listPartsCount, 1)
            guard case .failure(let error) = result,
                  case .authError(let description, _, _) = error else {
                XCTFail("Expected StorageError.authError")
                return
            }
            XCTAssertEqual(description, "AuthError")
            listPartsExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCompleteMultipartUpload_withSuccess_shouldSucceed() {
        let completeMultipartUploadExpectation = expectation(description: "Complete Multipart Upload")
        awsS3.completeMultipartUploadResult = .success(.init(
            eTag: "eTag"
        ))
        adapter.completeMultipartUpload(.init(
            bucket: "bucket",
            key: "key",
            uploadId: "uploadId",
            parts: [.init(partNumber: 1, eTag: "eTag1"), .init(partNumber: 2, eTag: "eTag2")]
        )) { result in
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .success(let response) = result else {
                XCTFail("Expected success")
                return
            }
            XCTAssertEqual(response.bucket, "bucket")
            XCTAssertEqual(response.key, "key")
            XCTAssertEqual(response.eTag, "eTag")
            completeMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with .unknown error
    func testCompleteMultipartUpload_withWrongResponse_shouldFail() {
        let completeMultipartUploadExpectation = expectation(description: "Complete Multipart Upload")
        adapter.completeMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId", parts: [])) { result in
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .failure(let error) = result,
                  case .unknown(let description, _) = error else {
                XCTFail("Expected StorageError.unknown")
                return
            }
            XCTAssertEqual(description, "Invalid response for completing multipart upload")
            completeMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCompleteMultipartUpload_withError_shouldFail() {
        let completeMultipartUploadExpectation = expectation(description: "Complete Multipart Upload")
        awsS3.completeMultipartUploadResult = .failure(StorageError.authError("AuthError", "", nil))
        adapter.completeMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId", parts: [])) { result in
            XCTAssertEqual(self.awsS3.completeMultipartUploadCount, 1)
            guard case .failure(let error) = result,
                  case .authError(let description, _, _) = error else {
                XCTFail("Expected StorageError.authError")
                return
            }
            XCTAssertEqual(description, "AuthError")
            completeMultipartUploadExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned
    func testAbortMultipartUpload_withSuccess_shouldSucceed() {
        let abortExpectation = expectation(description: "Abort Multipart Upload")
        adapter.abortMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId")) { result in
            XCTAssertEqual(self.awsS3.abortMultipartUploadCount, 1)
            guard case .success = result else {
                XCTFail("Expected success")
                return
            }
            abortExpectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testAbortMultipartUpload_withError_shouldFail() {
        let abortExpectation = expectation(description: "Abort Multipart Upload")
        awsS3.abortMultipartUploadResult = .failure(StorageError.keyNotFound("InvalidKey", "", "", nil))
        adapter.abortMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId")) { result in
            XCTAssertEqual(self.awsS3.abortMultipartUploadCount, 1)
            guard case .failure(let error) = result,
                  case .keyNotFound(let key, _, _, _) = error else {
                XCTFail("Expected StorageError.keyNotFound")
                return
            }
            XCTAssertEqual(key, "InvalidKey")
            abortExpectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: getS3 is invoked
    /// Then: The underlying S3ClientProtocol instance is returned
    func testGetS3() {
        XCTAssertTrue(adapter.getS3() is S3ClientMock)
    }
}

private class S3ClientMock: S3ClientProtocol {
    var deleteObjectCount = 0
    var deleteObjectResult: Result<DeleteObjectOutputResponse, Error> = .success(.init())
    func deleteObject(input: AWSS3.DeleteObjectInput) async throws -> AWSS3.DeleteObjectOutputResponse {
        deleteObjectCount += 1
        return try deleteObjectResult.get()
    }
    
    var listObjectsV2Count = 0
    var listObjectsV2Result: Result<ListObjectsV2OutputResponse, Error> = .success(.init())
    func listObjectsV2(input: AWSS3.ListObjectsV2Input) async throws -> AWSS3.ListObjectsV2OutputResponse {
        listObjectsV2Count += 1
        return try listObjectsV2Result.get()
    }
    
    var createMultipartUploadCount = 0
    var createMultipartUploadResult: Result<CreateMultipartUploadOutputResponse, Error> = .success(.init())
    func createMultipartUpload(input: AWSS3.CreateMultipartUploadInput) async throws -> AWSS3.CreateMultipartUploadOutputResponse {
        createMultipartUploadCount += 1
        return try createMultipartUploadResult.get()
    }
    
    var listPartsCount = 0
    var listPartsResult: Result<ListPartsOutputResponse, Error> = .success(.init())
    func listParts(input: AWSS3.ListPartsInput) async throws -> AWSS3.ListPartsOutputResponse {
        listPartsCount += 1
        return try listPartsResult.get()
    }
    
    var completeMultipartUploadCount = 0
    var completeMultipartUploadResult: Result<CompleteMultipartUploadOutputResponse, Error> = .success(.init())
    func completeMultipartUpload(input: AWSS3.CompleteMultipartUploadInput) async throws -> AWSS3.CompleteMultipartUploadOutputResponse {
        completeMultipartUploadCount += 1
        return try completeMultipartUploadResult.get()
    }
    
    var abortMultipartUploadCount = 0
    var abortMultipartUploadResult: Result<AbortMultipartUploadOutputResponse, Error> = .success(.init())
    func abortMultipartUpload(input: AWSS3.AbortMultipartUploadInput) async throws -> AWSS3.AbortMultipartUploadOutputResponse {
        abortMultipartUploadCount += 1
        return try abortMultipartUploadResult.get()
    }
    
    func copyObject(input: AWSS3.CopyObjectInput) async throws -> AWSS3.CopyObjectOutputResponse {
        fatalError("Not Implemented")
    }
    
    func createBucket(input: AWSS3.CreateBucketInput) async throws -> AWSS3.CreateBucketOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucket(input: AWSS3.DeleteBucketInput) async throws -> AWSS3.DeleteBucketOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketAnalyticsConfiguration(input: AWSS3.DeleteBucketAnalyticsConfigurationInput) async throws -> AWSS3.DeleteBucketAnalyticsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketCors(input: AWSS3.DeleteBucketCorsInput) async throws -> AWSS3.DeleteBucketCorsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketEncryption(input: AWSS3.DeleteBucketEncryptionInput) async throws -> AWSS3.DeleteBucketEncryptionOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketIntelligentTieringConfiguration(input: AWSS3.DeleteBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.DeleteBucketIntelligentTieringConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketInventoryConfiguration(input: AWSS3.DeleteBucketInventoryConfigurationInput) async throws -> AWSS3.DeleteBucketInventoryConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketLifecycle(input: AWSS3.DeleteBucketLifecycleInput) async throws -> AWSS3.DeleteBucketLifecycleOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketMetricsConfiguration(input: AWSS3.DeleteBucketMetricsConfigurationInput) async throws -> AWSS3.DeleteBucketMetricsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketOwnershipControls(input: AWSS3.DeleteBucketOwnershipControlsInput) async throws -> AWSS3.DeleteBucketOwnershipControlsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketPolicy(input: AWSS3.DeleteBucketPolicyInput) async throws -> AWSS3.DeleteBucketPolicyOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketReplication(input: AWSS3.DeleteBucketReplicationInput) async throws -> AWSS3.DeleteBucketReplicationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketTagging(input: AWSS3.DeleteBucketTaggingInput) async throws -> AWSS3.DeleteBucketTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteBucketWebsite(input: AWSS3.DeleteBucketWebsiteInput) async throws -> AWSS3.DeleteBucketWebsiteOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteObjects(input: AWSS3.DeleteObjectsInput) async throws -> AWSS3.DeleteObjectsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deleteObjectTagging(input: AWSS3.DeleteObjectTaggingInput) async throws -> AWSS3.DeleteObjectTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func deletePublicAccessBlock(input: AWSS3.DeletePublicAccessBlockInput) async throws -> AWSS3.DeletePublicAccessBlockOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketAccelerateConfiguration(input: AWSS3.GetBucketAccelerateConfigurationInput) async throws -> AWSS3.GetBucketAccelerateConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketAcl(input: AWSS3.GetBucketAclInput) async throws -> AWSS3.GetBucketAclOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketAnalyticsConfiguration(input: AWSS3.GetBucketAnalyticsConfigurationInput) async throws -> AWSS3.GetBucketAnalyticsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketCors(input: AWSS3.GetBucketCorsInput) async throws -> AWSS3.GetBucketCorsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketEncryption(input: AWSS3.GetBucketEncryptionInput) async throws -> AWSS3.GetBucketEncryptionOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketIntelligentTieringConfiguration(input: AWSS3.GetBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.GetBucketIntelligentTieringConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketInventoryConfiguration(input: AWSS3.GetBucketInventoryConfigurationInput) async throws -> AWSS3.GetBucketInventoryConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketLifecycleConfiguration(input: AWSS3.GetBucketLifecycleConfigurationInput) async throws -> AWSS3.GetBucketLifecycleConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketLocation(input: AWSS3.GetBucketLocationInput) async throws -> AWSS3.GetBucketLocationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketLogging(input: AWSS3.GetBucketLoggingInput) async throws -> AWSS3.GetBucketLoggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketMetricsConfiguration(input: AWSS3.GetBucketMetricsConfigurationInput) async throws -> AWSS3.GetBucketMetricsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketNotificationConfiguration(input: AWSS3.GetBucketNotificationConfigurationInput) async throws -> AWSS3.GetBucketNotificationConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketOwnershipControls(input: AWSS3.GetBucketOwnershipControlsInput) async throws -> AWSS3.GetBucketOwnershipControlsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketPolicy(input: AWSS3.GetBucketPolicyInput) async throws -> AWSS3.GetBucketPolicyOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketPolicyStatus(input: AWSS3.GetBucketPolicyStatusInput) async throws -> AWSS3.GetBucketPolicyStatusOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketReplication(input: AWSS3.GetBucketReplicationInput) async throws -> AWSS3.GetBucketReplicationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketRequestPayment(input: AWSS3.GetBucketRequestPaymentInput) async throws -> AWSS3.GetBucketRequestPaymentOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketTagging(input: AWSS3.GetBucketTaggingInput) async throws -> AWSS3.GetBucketTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketVersioning(input: AWSS3.GetBucketVersioningInput) async throws -> AWSS3.GetBucketVersioningOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getBucketWebsite(input: AWSS3.GetBucketWebsiteInput) async throws -> AWSS3.GetBucketWebsiteOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObject(input: AWSS3.GetObjectInput) async throws -> AWSS3.GetObjectOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectAcl(input: AWSS3.GetObjectAclInput) async throws -> AWSS3.GetObjectAclOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectAttributes(input: AWSS3.GetObjectAttributesInput) async throws -> AWSS3.GetObjectAttributesOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectLegalHold(input: AWSS3.GetObjectLegalHoldInput) async throws -> AWSS3.GetObjectLegalHoldOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectLockConfiguration(input: AWSS3.GetObjectLockConfigurationInput) async throws -> AWSS3.GetObjectLockConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectRetention(input: AWSS3.GetObjectRetentionInput) async throws -> AWSS3.GetObjectRetentionOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectTagging(input: AWSS3.GetObjectTaggingInput) async throws -> AWSS3.GetObjectTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getObjectTorrent(input: AWSS3.GetObjectTorrentInput) async throws -> AWSS3.GetObjectTorrentOutputResponse {
        fatalError("Not Implemented")
    }
    
    func getPublicAccessBlock(input: AWSS3.GetPublicAccessBlockInput) async throws -> AWSS3.GetPublicAccessBlockOutputResponse {
        fatalError("Not Implemented")
    }
    
    func headBucket(input: AWSS3.HeadBucketInput) async throws -> AWSS3.HeadBucketOutputResponse {
        fatalError("Not Implemented")
    }
    
    func headObject(input: AWSS3.HeadObjectInput) async throws -> AWSS3.HeadObjectOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listBucketAnalyticsConfigurations(input: AWSS3.ListBucketAnalyticsConfigurationsInput) async throws -> AWSS3.ListBucketAnalyticsConfigurationsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listBucketIntelligentTieringConfigurations(input: AWSS3.ListBucketIntelligentTieringConfigurationsInput) async throws -> AWSS3.ListBucketIntelligentTieringConfigurationsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listBucketInventoryConfigurations(input: AWSS3.ListBucketInventoryConfigurationsInput) async throws -> AWSS3.ListBucketInventoryConfigurationsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listBucketMetricsConfigurations(input: AWSS3.ListBucketMetricsConfigurationsInput) async throws -> AWSS3.ListBucketMetricsConfigurationsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listBuckets(input: AWSS3.ListBucketsInput) async throws -> AWSS3.ListBucketsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listMultipartUploads(input: AWSS3.ListMultipartUploadsInput) async throws -> AWSS3.ListMultipartUploadsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listObjects(input: AWSS3.ListObjectsInput) async throws -> AWSS3.ListObjectsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func listObjectVersions(input: AWSS3.ListObjectVersionsInput) async throws -> AWSS3.ListObjectVersionsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketAccelerateConfiguration(input: AWSS3.PutBucketAccelerateConfigurationInput) async throws -> AWSS3.PutBucketAccelerateConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketAcl(input: AWSS3.PutBucketAclInput) async throws -> AWSS3.PutBucketAclOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketAnalyticsConfiguration(input: AWSS3.PutBucketAnalyticsConfigurationInput) async throws -> AWSS3.PutBucketAnalyticsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketCors(input: AWSS3.PutBucketCorsInput) async throws -> AWSS3.PutBucketCorsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketEncryption(input: AWSS3.PutBucketEncryptionInput) async throws -> AWSS3.PutBucketEncryptionOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketIntelligentTieringConfiguration(input: AWSS3.PutBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.PutBucketIntelligentTieringConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketInventoryConfiguration(input: AWSS3.PutBucketInventoryConfigurationInput) async throws -> AWSS3.PutBucketInventoryConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketLifecycleConfiguration(input: AWSS3.PutBucketLifecycleConfigurationInput) async throws -> AWSS3.PutBucketLifecycleConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketLogging(input: AWSS3.PutBucketLoggingInput) async throws -> AWSS3.PutBucketLoggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketMetricsConfiguration(input: AWSS3.PutBucketMetricsConfigurationInput) async throws -> AWSS3.PutBucketMetricsConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketNotificationConfiguration(input: AWSS3.PutBucketNotificationConfigurationInput) async throws -> AWSS3.PutBucketNotificationConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketOwnershipControls(input: AWSS3.PutBucketOwnershipControlsInput) async throws -> AWSS3.PutBucketOwnershipControlsOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketPolicy(input: AWSS3.PutBucketPolicyInput) async throws -> AWSS3.PutBucketPolicyOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketReplication(input: AWSS3.PutBucketReplicationInput) async throws -> AWSS3.PutBucketReplicationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketRequestPayment(input: AWSS3.PutBucketRequestPaymentInput) async throws -> AWSS3.PutBucketRequestPaymentOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketTagging(input: AWSS3.PutBucketTaggingInput) async throws -> AWSS3.PutBucketTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketVersioning(input: AWSS3.PutBucketVersioningInput) async throws -> AWSS3.PutBucketVersioningOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putBucketWebsite(input: AWSS3.PutBucketWebsiteInput) async throws -> AWSS3.PutBucketWebsiteOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObject(input: AWSS3.PutObjectInput) async throws -> AWSS3.PutObjectOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObjectAcl(input: AWSS3.PutObjectAclInput) async throws -> AWSS3.PutObjectAclOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObjectLegalHold(input: AWSS3.PutObjectLegalHoldInput) async throws -> AWSS3.PutObjectLegalHoldOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObjectLockConfiguration(input: AWSS3.PutObjectLockConfigurationInput) async throws -> AWSS3.PutObjectLockConfigurationOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObjectRetention(input: AWSS3.PutObjectRetentionInput) async throws -> AWSS3.PutObjectRetentionOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putObjectTagging(input: AWSS3.PutObjectTaggingInput) async throws -> AWSS3.PutObjectTaggingOutputResponse {
        fatalError("Not Implemented")
    }
    
    func putPublicAccessBlock(input: AWSS3.PutPublicAccessBlockInput) async throws -> AWSS3.PutPublicAccessBlockOutputResponse {
        fatalError("Not Implemented")
    }
    
    func restoreObject(input: AWSS3.RestoreObjectInput) async throws -> AWSS3.RestoreObjectOutputResponse {
        fatalError("Not Implemented")
    }
    
    func selectObjectContent(input: AWSS3.SelectObjectContentInput) async throws -> AWSS3.SelectObjectContentOutputResponse {
        fatalError("Not Implemented")
    }
    
    func uploadPart(input: AWSS3.UploadPartInput) async throws -> AWSS3.UploadPartOutputResponse {
        fatalError("Not Implemented")
    }
    
    func uploadPartCopy(input: AWSS3.UploadPartCopyInput) async throws -> AWSS3.UploadPartCopyOutputResponse {
        fatalError("Not Implemented")
    }
    
    func writeGetObjectResponse(input: AWSS3.WriteGetObjectResponseInput) async throws -> AWSS3.WriteGetObjectResponseOutputResponse {
        fatalError("Not Implemented")
    }
}
