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
    func testDeleteObject_withSuccess_shouldSucceed() async {
        let deleteExpectation = expectation(description: "Delete Object")
        adapter.deleteObject(.init(bucket: "bucket", key: "key")) { result in
            XCTAssertEqual(self.awsS3.deleteObjectCount, 1)
            guard case .success = result else {
                XCTFail("Expected success")
                return
            }
            deleteExpectation.fulfill()
        }

        await fulfillment(of: [deleteExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: deleteObject is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testDeleteObject_withError_shouldFail() async {
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

        await fulfillment(of: [deleteExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns a list of objects
    /// Then: A .success result is returned containing the corresponding list items
    func testListObjectsV2_withSuccess_shouldSucceed() async {
        let listExpectation = expectation(description: "List Objects")
        awsS3.listObjectsV2Result = .success(ListObjectsV2Output(
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

        await fulfillment(of: [listExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listObjectsV2 is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListObjectsV2_withError_shouldFail() async {
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

        await fulfillment(of: [listExpectation], timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCreateMultipartUpload_withSuccess_shouldSucceed() async {
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

        await fulfillment(of: [createMultipartUploadExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .uknown error
    func testCreateMultipartUpload_withWrongResponse_shouldFail() async {
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

        await fulfillment(of: [createMultipartUploadExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: createMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCreateMultipartUpload_withError_shouldFail() async {
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
        await fulfillment(of: [createMultipartUploadExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testListParts_withSuccess_shouldSucceed() async {
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

        await fulfillment(of: [listPartsExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with an .unknown error
    func testListParts_withWrongResponse_shouldFail() async {
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

        await fulfillment(of: [listPartsExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: listParts is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testListParts_withError_shouldFail() async {
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

        await fulfillment(of: [listPartsExpectation], timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned containing the corresponding parsed response
    func testCompleteMultipartUpload_withSuccess_shouldSucceed() async {
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

        await fulfillment(of: [completeMultipartUploadExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an invalid response
    /// Then: A .failure result is returned with .unknown error
    func testCompleteMultipartUpload_withWrongResponse_shouldFail() async {
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

        await fulfillment(of: [completeMultipartUploadExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: completeMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testCompleteMultipartUpload_withError_shouldFail() async {
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

        await fulfillment(of: [completeMultipartUploadExpectation], timeout: 1)
    }
    
    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns a valid response
    /// Then: A .success result is returned
    func testAbortMultipartUpload_withSuccess_shouldSucceed() async {
        let abortExpectation = expectation(description: "Abort Multipart Upload")
        adapter.abortMultipartUpload(.init(bucket: "bucket", key: "key", uploadId: "uploadId")) { result in
            XCTAssertEqual(self.awsS3.abortMultipartUploadCount, 1)
            guard case .success = result else {
                XCTFail("Expected success")
                return
            }
            abortExpectation.fulfill()
        }

        await fulfillment(of: [abortExpectation], timeout: 1)
    }

    /// Given: An AWSS3Adapter
    /// When: abortMultipartUpload is invoked and the s3 client returns an error
    /// Then: A .failure result is returned
    func testAbortMultipartUpload_withError_shouldFail() async {
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
        await fulfillment(of: [abortExpectation], timeout: 1)
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
    var deleteObjectResult: Result<DeleteObjectOutput, Error> = .success(.init())
    func deleteObject(input: AWSS3.DeleteObjectInput) async throws -> AWSS3.DeleteObjectOutput {
        deleteObjectCount += 1
        return try deleteObjectResult.get()
    }
    
    var listObjectsV2Count = 0
    var listObjectsV2Result: Result<ListObjectsV2Output, Error> = .success(.init())
    func listObjectsV2(input: AWSS3.ListObjectsV2Input) async throws -> AWSS3.ListObjectsV2Output {
        listObjectsV2Count += 1
        return try listObjectsV2Result.get()
    }
    
    var createMultipartUploadCount = 0
    var createMultipartUploadResult: Result<CreateMultipartUploadOutput, Error> = .success(.init())
    func createMultipartUpload(input: AWSS3.CreateMultipartUploadInput) async throws -> AWSS3.CreateMultipartUploadOutput {
        createMultipartUploadCount += 1
        return try createMultipartUploadResult.get()
    }
    
    var listPartsCount = 0
    var listPartsResult: Result<ListPartsOutput, Error> = .success(.init())
    func listParts(input: AWSS3.ListPartsInput) async throws -> AWSS3.ListPartsOutput {
        listPartsCount += 1
        return try listPartsResult.get()
    }
    
    var completeMultipartUploadCount = 0
    var completeMultipartUploadResult: Result<CompleteMultipartUploadOutput, Error> = .success(.init())
    func completeMultipartUpload(input: AWSS3.CompleteMultipartUploadInput) async throws -> AWSS3.CompleteMultipartUploadOutput {
        completeMultipartUploadCount += 1
        return try completeMultipartUploadResult.get()
    }
    
    var abortMultipartUploadCount = 0
    var abortMultipartUploadResult: Result<AbortMultipartUploadOutput, Error> = .success(.init())
    func abortMultipartUpload(input: AWSS3.AbortMultipartUploadInput) async throws -> AWSS3.AbortMultipartUploadOutput {
        abortMultipartUploadCount += 1
        return try abortMultipartUploadResult.get()
    }
    
    func copyObject(input: AWSS3.CopyObjectInput) async throws -> AWSS3.CopyObjectOutput {
        fatalError("Not Implemented")
    }
    
    func createBucket(input: AWSS3.CreateBucketInput) async throws -> AWSS3.CreateBucketOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucket(input: AWSS3.DeleteBucketInput) async throws -> AWSS3.DeleteBucketOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketAnalyticsConfiguration(input: AWSS3.DeleteBucketAnalyticsConfigurationInput) async throws -> AWSS3.DeleteBucketAnalyticsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketCors(input: AWSS3.DeleteBucketCorsInput) async throws -> AWSS3.DeleteBucketCorsOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketEncryption(input: AWSS3.DeleteBucketEncryptionInput) async throws -> AWSS3.DeleteBucketEncryptionOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketIntelligentTieringConfiguration(input: AWSS3.DeleteBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.DeleteBucketIntelligentTieringConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketInventoryConfiguration(input: AWSS3.DeleteBucketInventoryConfigurationInput) async throws -> AWSS3.DeleteBucketInventoryConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketLifecycle(input: AWSS3.DeleteBucketLifecycleInput) async throws -> AWSS3.DeleteBucketLifecycleOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketMetricsConfiguration(input: AWSS3.DeleteBucketMetricsConfigurationInput) async throws -> AWSS3.DeleteBucketMetricsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketOwnershipControls(input: AWSS3.DeleteBucketOwnershipControlsInput) async throws -> AWSS3.DeleteBucketOwnershipControlsOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketPolicy(input: AWSS3.DeleteBucketPolicyInput) async throws -> AWSS3.DeleteBucketPolicyOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketReplication(input: AWSS3.DeleteBucketReplicationInput) async throws -> AWSS3.DeleteBucketReplicationOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketTagging(input: AWSS3.DeleteBucketTaggingInput) async throws -> AWSS3.DeleteBucketTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func deleteBucketWebsite(input: AWSS3.DeleteBucketWebsiteInput) async throws -> AWSS3.DeleteBucketWebsiteOutput {
        fatalError("Not Implemented")
    }
    
    func deleteObjects(input: AWSS3.DeleteObjectsInput) async throws -> AWSS3.DeleteObjectsOutput {
        fatalError("Not Implemented")
    }
    
    func deleteObjectTagging(input: AWSS3.DeleteObjectTaggingInput) async throws -> AWSS3.DeleteObjectTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func deletePublicAccessBlock(input: AWSS3.DeletePublicAccessBlockInput) async throws -> AWSS3.DeletePublicAccessBlockOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketAccelerateConfiguration(input: AWSS3.GetBucketAccelerateConfigurationInput) async throws -> AWSS3.GetBucketAccelerateConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketAcl(input: AWSS3.GetBucketAclInput) async throws -> AWSS3.GetBucketAclOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketAnalyticsConfiguration(input: AWSS3.GetBucketAnalyticsConfigurationInput) async throws -> AWSS3.GetBucketAnalyticsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketCors(input: AWSS3.GetBucketCorsInput) async throws -> AWSS3.GetBucketCorsOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketEncryption(input: AWSS3.GetBucketEncryptionInput) async throws -> AWSS3.GetBucketEncryptionOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketIntelligentTieringConfiguration(input: AWSS3.GetBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.GetBucketIntelligentTieringConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketInventoryConfiguration(input: AWSS3.GetBucketInventoryConfigurationInput) async throws -> AWSS3.GetBucketInventoryConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketLifecycleConfiguration(input: AWSS3.GetBucketLifecycleConfigurationInput) async throws -> AWSS3.GetBucketLifecycleConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketLocation(input: AWSS3.GetBucketLocationInput) async throws -> AWSS3.GetBucketLocationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketLogging(input: AWSS3.GetBucketLoggingInput) async throws -> AWSS3.GetBucketLoggingOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketMetricsConfiguration(input: AWSS3.GetBucketMetricsConfigurationInput) async throws -> AWSS3.GetBucketMetricsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketNotificationConfiguration(input: AWSS3.GetBucketNotificationConfigurationInput) async throws -> AWSS3.GetBucketNotificationConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketOwnershipControls(input: AWSS3.GetBucketOwnershipControlsInput) async throws -> AWSS3.GetBucketOwnershipControlsOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketPolicy(input: AWSS3.GetBucketPolicyInput) async throws -> AWSS3.GetBucketPolicyOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketPolicyStatus(input: AWSS3.GetBucketPolicyStatusInput) async throws -> AWSS3.GetBucketPolicyStatusOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketReplication(input: AWSS3.GetBucketReplicationInput) async throws -> AWSS3.GetBucketReplicationOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketRequestPayment(input: AWSS3.GetBucketRequestPaymentInput) async throws -> AWSS3.GetBucketRequestPaymentOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketTagging(input: AWSS3.GetBucketTaggingInput) async throws -> AWSS3.GetBucketTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketVersioning(input: AWSS3.GetBucketVersioningInput) async throws -> AWSS3.GetBucketVersioningOutput {
        fatalError("Not Implemented")
    }
    
    func getBucketWebsite(input: AWSS3.GetBucketWebsiteInput) async throws -> AWSS3.GetBucketWebsiteOutput {
        fatalError("Not Implemented")
    }
    
    func getObject(input: AWSS3.GetObjectInput) async throws -> AWSS3.GetObjectOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectAcl(input: AWSS3.GetObjectAclInput) async throws -> AWSS3.GetObjectAclOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectAttributes(input: AWSS3.GetObjectAttributesInput) async throws -> AWSS3.GetObjectAttributesOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectLegalHold(input: AWSS3.GetObjectLegalHoldInput) async throws -> AWSS3.GetObjectLegalHoldOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectLockConfiguration(input: AWSS3.GetObjectLockConfigurationInput) async throws -> AWSS3.GetObjectLockConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectRetention(input: AWSS3.GetObjectRetentionInput) async throws -> AWSS3.GetObjectRetentionOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectTagging(input: AWSS3.GetObjectTaggingInput) async throws -> AWSS3.GetObjectTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func getObjectTorrent(input: AWSS3.GetObjectTorrentInput) async throws -> AWSS3.GetObjectTorrentOutput {
        fatalError("Not Implemented")
    }
    
    func getPublicAccessBlock(input: AWSS3.GetPublicAccessBlockInput) async throws -> AWSS3.GetPublicAccessBlockOutput {
        fatalError("Not Implemented")
    }
    
    func headBucket(input: AWSS3.HeadBucketInput) async throws -> AWSS3.HeadBucketOutput {
        fatalError("Not Implemented")
    }
    
    func headObject(input: AWSS3.HeadObjectInput) async throws -> AWSS3.HeadObjectOutput {
        fatalError("Not Implemented")
    }
    
    func listBucketAnalyticsConfigurations(input: AWSS3.ListBucketAnalyticsConfigurationsInput) async throws -> AWSS3.ListBucketAnalyticsConfigurationsOutput {
        fatalError("Not Implemented")
    }
    
    func listBucketIntelligentTieringConfigurations(input: AWSS3.ListBucketIntelligentTieringConfigurationsInput) async throws -> AWSS3.ListBucketIntelligentTieringConfigurationsOutput {
        fatalError("Not Implemented")
    }
    
    func listBucketInventoryConfigurations(input: AWSS3.ListBucketInventoryConfigurationsInput) async throws -> AWSS3.ListBucketInventoryConfigurationsOutput {
        fatalError("Not Implemented")
    }
    
    func listBucketMetricsConfigurations(input: AWSS3.ListBucketMetricsConfigurationsInput) async throws -> AWSS3.ListBucketMetricsConfigurationsOutput {
        fatalError("Not Implemented")
    }
    
    func listBuckets(input: AWSS3.ListBucketsInput) async throws -> AWSS3.ListBucketsOutput {
        fatalError("Not Implemented")
    }
    
    func listMultipartUploads(input: AWSS3.ListMultipartUploadsInput) async throws -> AWSS3.ListMultipartUploadsOutput {
        fatalError("Not Implemented")
    }
    
    func listObjects(input: AWSS3.ListObjectsInput) async throws -> AWSS3.ListObjectsOutput {
        fatalError("Not Implemented")
    }
    
    func listObjectVersions(input: AWSS3.ListObjectVersionsInput) async throws -> AWSS3.ListObjectVersionsOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketAccelerateConfiguration(input: AWSS3.PutBucketAccelerateConfigurationInput) async throws -> AWSS3.PutBucketAccelerateConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketAcl(input: AWSS3.PutBucketAclInput) async throws -> AWSS3.PutBucketAclOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketAnalyticsConfiguration(input: AWSS3.PutBucketAnalyticsConfigurationInput) async throws -> AWSS3.PutBucketAnalyticsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketCors(input: AWSS3.PutBucketCorsInput) async throws -> AWSS3.PutBucketCorsOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketEncryption(input: AWSS3.PutBucketEncryptionInput) async throws -> AWSS3.PutBucketEncryptionOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketIntelligentTieringConfiguration(input: AWSS3.PutBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.PutBucketIntelligentTieringConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketInventoryConfiguration(input: AWSS3.PutBucketInventoryConfigurationInput) async throws -> AWSS3.PutBucketInventoryConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketLifecycleConfiguration(input: AWSS3.PutBucketLifecycleConfigurationInput) async throws -> AWSS3.PutBucketLifecycleConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketLogging(input: AWSS3.PutBucketLoggingInput) async throws -> AWSS3.PutBucketLoggingOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketMetricsConfiguration(input: AWSS3.PutBucketMetricsConfigurationInput) async throws -> AWSS3.PutBucketMetricsConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketNotificationConfiguration(input: AWSS3.PutBucketNotificationConfigurationInput) async throws -> AWSS3.PutBucketNotificationConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketOwnershipControls(input: AWSS3.PutBucketOwnershipControlsInput) async throws -> AWSS3.PutBucketOwnershipControlsOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketPolicy(input: AWSS3.PutBucketPolicyInput) async throws -> AWSS3.PutBucketPolicyOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketReplication(input: AWSS3.PutBucketReplicationInput) async throws -> AWSS3.PutBucketReplicationOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketRequestPayment(input: AWSS3.PutBucketRequestPaymentInput) async throws -> AWSS3.PutBucketRequestPaymentOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketTagging(input: AWSS3.PutBucketTaggingInput) async throws -> AWSS3.PutBucketTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketVersioning(input: AWSS3.PutBucketVersioningInput) async throws -> AWSS3.PutBucketVersioningOutput {
        fatalError("Not Implemented")
    }
    
    func putBucketWebsite(input: AWSS3.PutBucketWebsiteInput) async throws -> AWSS3.PutBucketWebsiteOutput {
        fatalError("Not Implemented")
    }
    
    func putObject(input: AWSS3.PutObjectInput) async throws -> AWSS3.PutObjectOutput {
        fatalError("Not Implemented")
    }
    
    func putObjectAcl(input: AWSS3.PutObjectAclInput) async throws -> AWSS3.PutObjectAclOutput {
        fatalError("Not Implemented")
    }
    
    func putObjectLegalHold(input: AWSS3.PutObjectLegalHoldInput) async throws -> AWSS3.PutObjectLegalHoldOutput {
        fatalError("Not Implemented")
    }
    
    func putObjectLockConfiguration(input: AWSS3.PutObjectLockConfigurationInput) async throws -> AWSS3.PutObjectLockConfigurationOutput {
        fatalError("Not Implemented")
    }
    
    func putObjectRetention(input: AWSS3.PutObjectRetentionInput) async throws -> AWSS3.PutObjectRetentionOutput {
        fatalError("Not Implemented")
    }
    
    func putObjectTagging(input: AWSS3.PutObjectTaggingInput) async throws -> AWSS3.PutObjectTaggingOutput {
        fatalError("Not Implemented")
    }
    
    func putPublicAccessBlock(input: AWSS3.PutPublicAccessBlockInput) async throws -> AWSS3.PutPublicAccessBlockOutput {
        fatalError("Not Implemented")
    }
    
    func restoreObject(input: AWSS3.RestoreObjectInput) async throws -> AWSS3.RestoreObjectOutput {
        fatalError("Not Implemented")
    }
    
    func selectObjectContent(input: AWSS3.SelectObjectContentInput) async throws -> AWSS3.SelectObjectContentOutput {
        fatalError("Not Implemented")
    }
    
    func uploadPart(input: AWSS3.UploadPartInput) async throws -> AWSS3.UploadPartOutput {
        fatalError("Not Implemented")
    }
    
    func uploadPartCopy(input: AWSS3.UploadPartCopyInput) async throws -> AWSS3.UploadPartCopyOutput {
        fatalError("Not Implemented")
    }
    
    func writeGetObjectResponse(input: AWSS3.WriteGetObjectResponseInput) async throws -> AWSS3.WriteGetObjectResponseOutput {
        fatalError("Not Implemented")
    }
}
