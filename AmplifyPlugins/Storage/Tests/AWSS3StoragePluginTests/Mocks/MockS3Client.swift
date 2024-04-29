//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Foundation
@testable import AWSS3StoragePlugin

/// - Tag: MockS3Client
final class MockS3Client {

    /// - Tag: MockS3ClientClientError
    enum ClientError: Error {
        case missingImplementation
        case missingResult
    }

    /// - Tag: MockS3Client.interactions
    var interactions: [String] = []

    /// Used by [MockS3Client.listObjectsV2](x-source-tag://MockS3Client.listObjectsV2)
    /// in order to extract results during each invocation.
    ///
    /// - Tag: MockS3Client.listObjectsV2Handler
    var listObjectsV2Handler: (ListObjectsV2Input) async throws -> ListObjectsV2Output = { _ in throw ClientError.missingResult }

    var headObjectHandler: (HeadObjectInput) async throws -> HeadObjectOutput = { _ in return HeadObjectOutput() }

    var deleteObjectHandler: ((DeleteObjectInput) async throws -> DeleteObjectOutput)? = nil
}

extension MockS3Client: S3ClientProtocol {

    /// - Tag: MockS3Client.listObjectsV2
    func listObjectsV2(input: AWSS3.ListObjectsV2Input) async throws -> AWSS3.ListObjectsV2Output {
        interactions.append("\(#function) bucket: \(input.bucket ?? "nil") prefix: \(input.prefix ?? "nil") continuationToken: \(input.continuationToken ?? "nil")")
        return try await listObjectsV2Handler(input)
    }

    func abortMultipartUpload(input: AWSS3.AbortMultipartUploadInput) async throws -> AWSS3.AbortMultipartUploadOutput {
        throw ClientError.missingImplementation
    }

    func completeMultipartUpload(input: AWSS3.CompleteMultipartUploadInput) async throws -> AWSS3.CompleteMultipartUploadOutput {
        throw ClientError.missingImplementation
    }

    func copyObject(input: AWSS3.CopyObjectInput) async throws -> AWSS3.CopyObjectOutput {
        throw ClientError.missingImplementation
    }

    func createBucket(input: AWSS3.CreateBucketInput) async throws -> AWSS3.CreateBucketOutput {
        throw ClientError.missingImplementation
    }

    func createMultipartUpload(input: AWSS3.CreateMultipartUploadInput) async throws -> AWSS3.CreateMultipartUploadOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucket(input: AWSS3.DeleteBucketInput) async throws -> AWSS3.DeleteBucketOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketAnalyticsConfiguration(input: AWSS3.DeleteBucketAnalyticsConfigurationInput) async throws -> AWSS3.DeleteBucketAnalyticsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketCors(input: AWSS3.DeleteBucketCorsInput) async throws -> AWSS3.DeleteBucketCorsOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketEncryption(input: AWSS3.DeleteBucketEncryptionInput) async throws -> AWSS3.DeleteBucketEncryptionOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketIntelligentTieringConfiguration(input: AWSS3.DeleteBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.DeleteBucketIntelligentTieringConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketInventoryConfiguration(input: AWSS3.DeleteBucketInventoryConfigurationInput) async throws -> AWSS3.DeleteBucketInventoryConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketLifecycle(input: AWSS3.DeleteBucketLifecycleInput) async throws -> AWSS3.DeleteBucketLifecycleOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketMetricsConfiguration(input: AWSS3.DeleteBucketMetricsConfigurationInput) async throws -> AWSS3.DeleteBucketMetricsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketOwnershipControls(input: AWSS3.DeleteBucketOwnershipControlsInput) async throws -> AWSS3.DeleteBucketOwnershipControlsOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketPolicy(input: AWSS3.DeleteBucketPolicyInput) async throws -> AWSS3.DeleteBucketPolicyOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketReplication(input: AWSS3.DeleteBucketReplicationInput) async throws -> AWSS3.DeleteBucketReplicationOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketTagging(input: AWSS3.DeleteBucketTaggingInput) async throws -> AWSS3.DeleteBucketTaggingOutput {
        throw ClientError.missingImplementation
    }

    func deleteBucketWebsite(input: AWSS3.DeleteBucketWebsiteInput) async throws -> AWSS3.DeleteBucketWebsiteOutput {
        throw ClientError.missingImplementation
    }

    func deleteObject(input: AWSS3.DeleteObjectInput) async throws -> AWSS3.DeleteObjectOutput {
        guard let deleteObjectHandler = deleteObjectHandler else {
            throw ClientError.missingImplementation
        }
        return try await deleteObjectHandler(input)
    }

    func deleteObjects(input: AWSS3.DeleteObjectsInput) async throws -> AWSS3.DeleteObjectsOutput {
        throw ClientError.missingImplementation
    }

    func deleteObjectTagging(input: AWSS3.DeleteObjectTaggingInput) async throws -> AWSS3.DeleteObjectTaggingOutput {
        throw ClientError.missingImplementation
    }

    func deletePublicAccessBlock(input: AWSS3.DeletePublicAccessBlockInput) async throws -> AWSS3.DeletePublicAccessBlockOutput {
        throw ClientError.missingImplementation
    }

    func getBucketAccelerateConfiguration(input: AWSS3.GetBucketAccelerateConfigurationInput) async throws -> AWSS3.GetBucketAccelerateConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketAcl(input: AWSS3.GetBucketAclInput) async throws -> AWSS3.GetBucketAclOutput {
        throw ClientError.missingImplementation
    }

    func getBucketAnalyticsConfiguration(input: AWSS3.GetBucketAnalyticsConfigurationInput) async throws -> AWSS3.GetBucketAnalyticsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketCors(input: AWSS3.GetBucketCorsInput) async throws -> AWSS3.GetBucketCorsOutput {
        throw ClientError.missingImplementation
    }

    func getBucketEncryption(input: AWSS3.GetBucketEncryptionInput) async throws -> AWSS3.GetBucketEncryptionOutput {
        throw ClientError.missingImplementation
    }

    func getBucketIntelligentTieringConfiguration(input: AWSS3.GetBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.GetBucketIntelligentTieringConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketInventoryConfiguration(input: AWSS3.GetBucketInventoryConfigurationInput) async throws -> AWSS3.GetBucketInventoryConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketLifecycleConfiguration(input: AWSS3.GetBucketLifecycleConfigurationInput) async throws -> AWSS3.GetBucketLifecycleConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketLocation(input: AWSS3.GetBucketLocationInput) async throws -> AWSS3.GetBucketLocationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketLogging(input: AWSS3.GetBucketLoggingInput) async throws -> AWSS3.GetBucketLoggingOutput {
        throw ClientError.missingImplementation
    }

    func getBucketMetricsConfiguration(input: AWSS3.GetBucketMetricsConfigurationInput) async throws -> AWSS3.GetBucketMetricsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketNotificationConfiguration(input: AWSS3.GetBucketNotificationConfigurationInput) async throws -> AWSS3.GetBucketNotificationConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketOwnershipControls(input: AWSS3.GetBucketOwnershipControlsInput) async throws -> AWSS3.GetBucketOwnershipControlsOutput {
        throw ClientError.missingImplementation
    }

    func getBucketPolicy(input: AWSS3.GetBucketPolicyInput) async throws -> AWSS3.GetBucketPolicyOutput {
        throw ClientError.missingImplementation
    }

    func getBucketPolicyStatus(input: AWSS3.GetBucketPolicyStatusInput) async throws -> AWSS3.GetBucketPolicyStatusOutput {
        throw ClientError.missingImplementation
    }

    func getBucketReplication(input: AWSS3.GetBucketReplicationInput) async throws -> AWSS3.GetBucketReplicationOutput {
        throw ClientError.missingImplementation
    }

    func getBucketRequestPayment(input: AWSS3.GetBucketRequestPaymentInput) async throws -> AWSS3.GetBucketRequestPaymentOutput {
        throw ClientError.missingImplementation
    }

    func getBucketTagging(input: AWSS3.GetBucketTaggingInput) async throws -> AWSS3.GetBucketTaggingOutput {
        throw ClientError.missingImplementation
    }

    func getBucketVersioning(input: AWSS3.GetBucketVersioningInput) async throws -> AWSS3.GetBucketVersioningOutput {
        throw ClientError.missingImplementation
    }

    func getBucketWebsite(input: AWSS3.GetBucketWebsiteInput) async throws -> AWSS3.GetBucketWebsiteOutput {
        throw ClientError.missingImplementation
    }

    func getObject(input: AWSS3.GetObjectInput) async throws -> AWSS3.GetObjectOutput {
        throw ClientError.missingImplementation
    }

    func getObjectAcl(input: AWSS3.GetObjectAclInput) async throws -> AWSS3.GetObjectAclOutput {
        throw ClientError.missingImplementation
    }

    func getObjectAttributes(input: AWSS3.GetObjectAttributesInput) async throws -> AWSS3.GetObjectAttributesOutput {
        throw ClientError.missingImplementation
    }

    func getObjectLegalHold(input: AWSS3.GetObjectLegalHoldInput) async throws -> AWSS3.GetObjectLegalHoldOutput {
        throw ClientError.missingImplementation
    }

    func getObjectLockConfiguration(input: AWSS3.GetObjectLockConfigurationInput) async throws -> AWSS3.GetObjectLockConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func getObjectRetention(input: AWSS3.GetObjectRetentionInput) async throws -> AWSS3.GetObjectRetentionOutput {
        throw ClientError.missingImplementation
    }

    func getObjectTagging(input: AWSS3.GetObjectTaggingInput) async throws -> AWSS3.GetObjectTaggingOutput {
        throw ClientError.missingImplementation
    }

    func getObjectTorrent(input: AWSS3.GetObjectTorrentInput) async throws -> AWSS3.GetObjectTorrentOutput {
        throw ClientError.missingImplementation
    }

    func getPublicAccessBlock(input: AWSS3.GetPublicAccessBlockInput) async throws -> AWSS3.GetPublicAccessBlockOutput {
        throw ClientError.missingImplementation
    }

    func headBucket(input: AWSS3.HeadBucketInput) async throws -> AWSS3.HeadBucketOutput {
        throw ClientError.missingImplementation
    }

    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutput {
        interactions.append(#function)
        return try await headObjectHandler(input)
    }

    func listBucketAnalyticsConfigurations(input: AWSS3.ListBucketAnalyticsConfigurationsInput) async throws -> AWSS3.ListBucketAnalyticsConfigurationsOutput {
        throw ClientError.missingImplementation
    }

    func listBucketIntelligentTieringConfigurations(input: AWSS3.ListBucketIntelligentTieringConfigurationsInput) async throws -> AWSS3.ListBucketIntelligentTieringConfigurationsOutput {
        throw ClientError.missingImplementation
    }

    func listBucketInventoryConfigurations(input: AWSS3.ListBucketInventoryConfigurationsInput) async throws -> AWSS3.ListBucketInventoryConfigurationsOutput {
        throw ClientError.missingImplementation
    }

    func listBucketMetricsConfigurations(input: AWSS3.ListBucketMetricsConfigurationsInput) async throws -> AWSS3.ListBucketMetricsConfigurationsOutput {
        throw ClientError.missingImplementation
    }

    func listBuckets(input: AWSS3.ListBucketsInput) async throws -> AWSS3.ListBucketsOutput {
        throw ClientError.missingImplementation
    }

    func listMultipartUploads(input: AWSS3.ListMultipartUploadsInput) async throws -> AWSS3.ListMultipartUploadsOutput {
        throw ClientError.missingImplementation
    }

    func listObjects(input: AWSS3.ListObjectsInput) async throws -> AWSS3.ListObjectsOutput {
        throw ClientError.missingImplementation
    }

    func listObjectVersions(input: AWSS3.ListObjectVersionsInput) async throws -> AWSS3.ListObjectVersionsOutput {
        throw ClientError.missingImplementation
    }

    func listParts(input: AWSS3.ListPartsInput) async throws -> AWSS3.ListPartsOutput {
        throw ClientError.missingImplementation
    }

    func putBucketAccelerateConfiguration(input: AWSS3.PutBucketAccelerateConfigurationInput) async throws -> AWSS3.PutBucketAccelerateConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketAcl(input: AWSS3.PutBucketAclInput) async throws -> AWSS3.PutBucketAclOutput {
        throw ClientError.missingImplementation
    }

    func putBucketAnalyticsConfiguration(input: AWSS3.PutBucketAnalyticsConfigurationInput) async throws -> AWSS3.PutBucketAnalyticsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketCors(input: AWSS3.PutBucketCorsInput) async throws -> AWSS3.PutBucketCorsOutput {
        throw ClientError.missingImplementation
    }

    func putBucketEncryption(input: AWSS3.PutBucketEncryptionInput) async throws -> AWSS3.PutBucketEncryptionOutput {
        throw ClientError.missingImplementation
    }

    func putBucketIntelligentTieringConfiguration(input: AWSS3.PutBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.PutBucketIntelligentTieringConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketInventoryConfiguration(input: AWSS3.PutBucketInventoryConfigurationInput) async throws -> AWSS3.PutBucketInventoryConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketLifecycleConfiguration(input: AWSS3.PutBucketLifecycleConfigurationInput) async throws -> AWSS3.PutBucketLifecycleConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketLogging(input: AWSS3.PutBucketLoggingInput) async throws -> AWSS3.PutBucketLoggingOutput {
        throw ClientError.missingImplementation
    }

    func putBucketMetricsConfiguration(input: AWSS3.PutBucketMetricsConfigurationInput) async throws -> AWSS3.PutBucketMetricsConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketNotificationConfiguration(input: AWSS3.PutBucketNotificationConfigurationInput) async throws -> AWSS3.PutBucketNotificationConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketOwnershipControls(input: AWSS3.PutBucketOwnershipControlsInput) async throws -> AWSS3.PutBucketOwnershipControlsOutput {
        throw ClientError.missingImplementation
    }

    func putBucketPolicy(input: AWSS3.PutBucketPolicyInput) async throws -> AWSS3.PutBucketPolicyOutput {
        throw ClientError.missingImplementation
    }

    func putBucketReplication(input: AWSS3.PutBucketReplicationInput) async throws -> AWSS3.PutBucketReplicationOutput {
        throw ClientError.missingImplementation
    }

    func putBucketRequestPayment(input: AWSS3.PutBucketRequestPaymentInput) async throws -> AWSS3.PutBucketRequestPaymentOutput {
        throw ClientError.missingImplementation
    }

    func putBucketTagging(input: AWSS3.PutBucketTaggingInput) async throws -> AWSS3.PutBucketTaggingOutput {
        throw ClientError.missingImplementation
    }

    func putBucketVersioning(input: AWSS3.PutBucketVersioningInput) async throws -> AWSS3.PutBucketVersioningOutput {
        throw ClientError.missingImplementation
    }

    func putBucketWebsite(input: AWSS3.PutBucketWebsiteInput) async throws -> AWSS3.PutBucketWebsiteOutput {
        throw ClientError.missingImplementation
    }

    func putObject(input: AWSS3.PutObjectInput) async throws -> AWSS3.PutObjectOutput {
        throw ClientError.missingImplementation
    }

    func putObjectAcl(input: AWSS3.PutObjectAclInput) async throws -> AWSS3.PutObjectAclOutput {
        throw ClientError.missingImplementation
    }

    func putObjectLegalHold(input: AWSS3.PutObjectLegalHoldInput) async throws -> AWSS3.PutObjectLegalHoldOutput {
        throw ClientError.missingImplementation
    }

    func putObjectLockConfiguration(input: AWSS3.PutObjectLockConfigurationInput) async throws -> AWSS3.PutObjectLockConfigurationOutput {
        throw ClientError.missingImplementation
    }

    func putObjectRetention(input: AWSS3.PutObjectRetentionInput) async throws -> AWSS3.PutObjectRetentionOutput {
        throw ClientError.missingImplementation
    }

    func putObjectTagging(input: AWSS3.PutObjectTaggingInput) async throws -> AWSS3.PutObjectTaggingOutput {
        throw ClientError.missingImplementation
    }

    func putPublicAccessBlock(input: AWSS3.PutPublicAccessBlockInput) async throws -> AWSS3.PutPublicAccessBlockOutput {
        throw ClientError.missingImplementation
    }

    func restoreObject(input: AWSS3.RestoreObjectInput) async throws -> AWSS3.RestoreObjectOutput {
        throw ClientError.missingImplementation
    }

    func selectObjectContent(input: AWSS3.SelectObjectContentInput) async throws -> AWSS3.SelectObjectContentOutput {
        throw ClientError.missingImplementation
    }

    func uploadPart(input: AWSS3.UploadPartInput) async throws -> AWSS3.UploadPartOutput {
        throw ClientError.missingImplementation
    }

    func uploadPartCopy(input: AWSS3.UploadPartCopyInput) async throws -> AWSS3.UploadPartCopyOutput {
        throw ClientError.missingImplementation
    }

    func writeGetObjectResponse(input: AWSS3.WriteGetObjectResponseInput) async throws -> AWSS3.WriteGetObjectResponseOutput {
        throw ClientError.missingImplementation
    }
}
