//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSS3
import Foundation

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
    var listObjectsV2Handler: (ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse = { _ in throw ClientError.missingResult }
}

extension MockS3Client: S3ClientProtocol {

    /// - Tag: MockS3Client.listObjectsV2
    func listObjectsV2(input: AWSS3.ListObjectsV2Input) async throws -> AWSS3.ListObjectsV2OutputResponse {
        interactions.append("\(#function) bucket: \(input.bucket ?? "nil") prefix: \(input.prefix ?? "nil") continuationToken: \(input.continuationToken ?? "nil")")
        return try await listObjectsV2Handler(input)
    }
    
    func abortMultipartUpload(input: AWSS3.AbortMultipartUploadInput) async throws -> AWSS3.AbortMultipartUploadOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func completeMultipartUpload(input: AWSS3.CompleteMultipartUploadInput) async throws -> AWSS3.CompleteMultipartUploadOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func copyObject(input: AWSS3.CopyObjectInput) async throws -> AWSS3.CopyObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func createBucket(input: AWSS3.CreateBucketInput) async throws -> AWSS3.CreateBucketOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func createMultipartUpload(input: AWSS3.CreateMultipartUploadInput) async throws -> AWSS3.CreateMultipartUploadOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucket(input: AWSS3.DeleteBucketInput) async throws -> AWSS3.DeleteBucketOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketAnalyticsConfiguration(input: AWSS3.DeleteBucketAnalyticsConfigurationInput) async throws -> AWSS3.DeleteBucketAnalyticsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketCors(input: AWSS3.DeleteBucketCorsInput) async throws -> AWSS3.DeleteBucketCorsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketEncryption(input: AWSS3.DeleteBucketEncryptionInput) async throws -> AWSS3.DeleteBucketEncryptionOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketIntelligentTieringConfiguration(input: AWSS3.DeleteBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.DeleteBucketIntelligentTieringConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketInventoryConfiguration(input: AWSS3.DeleteBucketInventoryConfigurationInput) async throws -> AWSS3.DeleteBucketInventoryConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketLifecycle(input: AWSS3.DeleteBucketLifecycleInput) async throws -> AWSS3.DeleteBucketLifecycleOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketMetricsConfiguration(input: AWSS3.DeleteBucketMetricsConfigurationInput) async throws -> AWSS3.DeleteBucketMetricsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketOwnershipControls(input: AWSS3.DeleteBucketOwnershipControlsInput) async throws -> AWSS3.DeleteBucketOwnershipControlsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketPolicy(input: AWSS3.DeleteBucketPolicyInput) async throws -> AWSS3.DeleteBucketPolicyOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketReplication(input: AWSS3.DeleteBucketReplicationInput) async throws -> AWSS3.DeleteBucketReplicationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketTagging(input: AWSS3.DeleteBucketTaggingInput) async throws -> AWSS3.DeleteBucketTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteBucketWebsite(input: AWSS3.DeleteBucketWebsiteInput) async throws -> AWSS3.DeleteBucketWebsiteOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteObject(input: AWSS3.DeleteObjectInput) async throws -> AWSS3.DeleteObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteObjects(input: AWSS3.DeleteObjectsInput) async throws -> AWSS3.DeleteObjectsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deleteObjectTagging(input: AWSS3.DeleteObjectTaggingInput) async throws -> AWSS3.DeleteObjectTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func deletePublicAccessBlock(input: AWSS3.DeletePublicAccessBlockInput) async throws -> AWSS3.DeletePublicAccessBlockOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketAccelerateConfiguration(input: AWSS3.GetBucketAccelerateConfigurationInput) async throws -> AWSS3.GetBucketAccelerateConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketAcl(input: AWSS3.GetBucketAclInput) async throws -> AWSS3.GetBucketAclOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketAnalyticsConfiguration(input: AWSS3.GetBucketAnalyticsConfigurationInput) async throws -> AWSS3.GetBucketAnalyticsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketCors(input: AWSS3.GetBucketCorsInput) async throws -> AWSS3.GetBucketCorsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketEncryption(input: AWSS3.GetBucketEncryptionInput) async throws -> AWSS3.GetBucketEncryptionOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketIntelligentTieringConfiguration(input: AWSS3.GetBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.GetBucketIntelligentTieringConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketInventoryConfiguration(input: AWSS3.GetBucketInventoryConfigurationInput) async throws -> AWSS3.GetBucketInventoryConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketLifecycleConfiguration(input: AWSS3.GetBucketLifecycleConfigurationInput) async throws -> AWSS3.GetBucketLifecycleConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketLocation(input: AWSS3.GetBucketLocationInput) async throws -> AWSS3.GetBucketLocationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketLogging(input: AWSS3.GetBucketLoggingInput) async throws -> AWSS3.GetBucketLoggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketMetricsConfiguration(input: AWSS3.GetBucketMetricsConfigurationInput) async throws -> AWSS3.GetBucketMetricsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketNotificationConfiguration(input: AWSS3.GetBucketNotificationConfigurationInput) async throws -> AWSS3.GetBucketNotificationConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketOwnershipControls(input: AWSS3.GetBucketOwnershipControlsInput) async throws -> AWSS3.GetBucketOwnershipControlsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketPolicy(input: AWSS3.GetBucketPolicyInput) async throws -> AWSS3.GetBucketPolicyOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketPolicyStatus(input: AWSS3.GetBucketPolicyStatusInput) async throws -> AWSS3.GetBucketPolicyStatusOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketReplication(input: AWSS3.GetBucketReplicationInput) async throws -> AWSS3.GetBucketReplicationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketRequestPayment(input: AWSS3.GetBucketRequestPaymentInput) async throws -> AWSS3.GetBucketRequestPaymentOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketTagging(input: AWSS3.GetBucketTaggingInput) async throws -> AWSS3.GetBucketTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketVersioning(input: AWSS3.GetBucketVersioningInput) async throws -> AWSS3.GetBucketVersioningOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getBucketWebsite(input: AWSS3.GetBucketWebsiteInput) async throws -> AWSS3.GetBucketWebsiteOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObject(input: AWSS3.GetObjectInput) async throws -> AWSS3.GetObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectAcl(input: AWSS3.GetObjectAclInput) async throws -> AWSS3.GetObjectAclOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectAttributes(input: AWSS3.GetObjectAttributesInput) async throws -> AWSS3.GetObjectAttributesOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectLegalHold(input: AWSS3.GetObjectLegalHoldInput) async throws -> AWSS3.GetObjectLegalHoldOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectLockConfiguration(input: AWSS3.GetObjectLockConfigurationInput) async throws -> AWSS3.GetObjectLockConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectRetention(input: AWSS3.GetObjectRetentionInput) async throws -> AWSS3.GetObjectRetentionOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectTagging(input: AWSS3.GetObjectTaggingInput) async throws -> AWSS3.GetObjectTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getObjectTorrent(input: AWSS3.GetObjectTorrentInput) async throws -> AWSS3.GetObjectTorrentOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func getPublicAccessBlock(input: AWSS3.GetPublicAccessBlockInput) async throws -> AWSS3.GetPublicAccessBlockOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func headBucket(input: AWSS3.HeadBucketInput) async throws -> AWSS3.HeadBucketOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func headObject(input: AWSS3.HeadObjectInput) async throws -> AWSS3.HeadObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listBucketAnalyticsConfigurations(input: AWSS3.ListBucketAnalyticsConfigurationsInput) async throws -> AWSS3.ListBucketAnalyticsConfigurationsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listBucketIntelligentTieringConfigurations(input: AWSS3.ListBucketIntelligentTieringConfigurationsInput) async throws -> AWSS3.ListBucketIntelligentTieringConfigurationsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listBucketInventoryConfigurations(input: AWSS3.ListBucketInventoryConfigurationsInput) async throws -> AWSS3.ListBucketInventoryConfigurationsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listBucketMetricsConfigurations(input: AWSS3.ListBucketMetricsConfigurationsInput) async throws -> AWSS3.ListBucketMetricsConfigurationsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listBuckets(input: AWSS3.ListBucketsInput) async throws -> AWSS3.ListBucketsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listMultipartUploads(input: AWSS3.ListMultipartUploadsInput) async throws -> AWSS3.ListMultipartUploadsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listObjects(input: AWSS3.ListObjectsInput) async throws -> AWSS3.ListObjectsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listObjectVersions(input: AWSS3.ListObjectVersionsInput) async throws -> AWSS3.ListObjectVersionsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func listParts(input: AWSS3.ListPartsInput) async throws -> AWSS3.ListPartsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketAccelerateConfiguration(input: AWSS3.PutBucketAccelerateConfigurationInput) async throws -> AWSS3.PutBucketAccelerateConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketAcl(input: AWSS3.PutBucketAclInput) async throws -> AWSS3.PutBucketAclOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketAnalyticsConfiguration(input: AWSS3.PutBucketAnalyticsConfigurationInput) async throws -> AWSS3.PutBucketAnalyticsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketCors(input: AWSS3.PutBucketCorsInput) async throws -> AWSS3.PutBucketCorsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketEncryption(input: AWSS3.PutBucketEncryptionInput) async throws -> AWSS3.PutBucketEncryptionOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketIntelligentTieringConfiguration(input: AWSS3.PutBucketIntelligentTieringConfigurationInput) async throws -> AWSS3.PutBucketIntelligentTieringConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketInventoryConfiguration(input: AWSS3.PutBucketInventoryConfigurationInput) async throws -> AWSS3.PutBucketInventoryConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketLifecycleConfiguration(input: AWSS3.PutBucketLifecycleConfigurationInput) async throws -> AWSS3.PutBucketLifecycleConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketLogging(input: AWSS3.PutBucketLoggingInput) async throws -> AWSS3.PutBucketLoggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketMetricsConfiguration(input: AWSS3.PutBucketMetricsConfigurationInput) async throws -> AWSS3.PutBucketMetricsConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketNotificationConfiguration(input: AWSS3.PutBucketNotificationConfigurationInput) async throws -> AWSS3.PutBucketNotificationConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketOwnershipControls(input: AWSS3.PutBucketOwnershipControlsInput) async throws -> AWSS3.PutBucketOwnershipControlsOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketPolicy(input: AWSS3.PutBucketPolicyInput) async throws -> AWSS3.PutBucketPolicyOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketReplication(input: AWSS3.PutBucketReplicationInput) async throws -> AWSS3.PutBucketReplicationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketRequestPayment(input: AWSS3.PutBucketRequestPaymentInput) async throws -> AWSS3.PutBucketRequestPaymentOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketTagging(input: AWSS3.PutBucketTaggingInput) async throws -> AWSS3.PutBucketTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketVersioning(input: AWSS3.PutBucketVersioningInput) async throws -> AWSS3.PutBucketVersioningOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putBucketWebsite(input: AWSS3.PutBucketWebsiteInput) async throws -> AWSS3.PutBucketWebsiteOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObject(input: AWSS3.PutObjectInput) async throws -> AWSS3.PutObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObjectAcl(input: AWSS3.PutObjectAclInput) async throws -> AWSS3.PutObjectAclOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObjectLegalHold(input: AWSS3.PutObjectLegalHoldInput) async throws -> AWSS3.PutObjectLegalHoldOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObjectLockConfiguration(input: AWSS3.PutObjectLockConfigurationInput) async throws -> AWSS3.PutObjectLockConfigurationOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObjectRetention(input: AWSS3.PutObjectRetentionInput) async throws -> AWSS3.PutObjectRetentionOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putObjectTagging(input: AWSS3.PutObjectTaggingInput) async throws -> AWSS3.PutObjectTaggingOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func putPublicAccessBlock(input: AWSS3.PutPublicAccessBlockInput) async throws -> AWSS3.PutPublicAccessBlockOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func restoreObject(input: AWSS3.RestoreObjectInput) async throws -> AWSS3.RestoreObjectOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func selectObjectContent(input: AWSS3.SelectObjectContentInput) async throws -> AWSS3.SelectObjectContentOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func uploadPart(input: AWSS3.UploadPartInput) async throws -> AWSS3.UploadPartOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func uploadPartCopy(input: AWSS3.UploadPartCopyInput) async throws -> AWSS3.UploadPartCopyOutputResponse {
        throw ClientError.missingImplementation
    }
    
    func writeGetObjectResponse(input: AWSS3.WriteGetObjectResponseInput) async throws -> AWSS3.WriteGetObjectResponseOutputResponse {
        throw ClientError.missingImplementation
    }
}
