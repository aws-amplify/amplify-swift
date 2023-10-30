//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension CreateMultipartUploadInput {
//    var headers: Headers {
//        var items = ClientRuntime.Headers()
//        if let acl = acl {
//            items.add(Header(name: "x-amz-acl", value: String(acl.rawValue)))
//        }
//        if let bucketKeyEnabled = bucketKeyEnabled {
//            items.add(Header(name: "x-amz-server-side-encryption-bucket-key-enabled", value: String(bucketKeyEnabled)))
//        }
//        if let cacheControl = cacheControl {
//            items.add(Header(name: "Cache-Control", value: String(cacheControl)))
//        }
//        if let checksumAlgorithm = checksumAlgorithm {
//            items.add(Header(name: "x-amz-checksum-algorithm", value: String(checksumAlgorithm.rawValue)))
//        }
//        if let contentDisposition = contentDisposition {
//            items.add(Header(name: "Content-Disposition", value: String(contentDisposition)))
//        }
//        if let contentEncoding = contentEncoding {
//            items.add(Header(name: "Content-Encoding", value: String(contentEncoding)))
//        }
//        if let contentLanguage = contentLanguage {
//            items.add(Header(name: "Content-Language", value: String(contentLanguage)))
//        }
//        if let contentType = contentType {
//            items.add(Header(name: "Content-Type", value: String(contentType)))
//        }
//        if let expectedBucketOwner = expectedBucketOwner {
//            items.add(Header(name: "x-amz-expected-bucket-owner", value: String(expectedBucketOwner)))
//        }
//        if let expires = expires {
//            items.add(Header(name: "Expires", value: String(TimestampFormatter(format: .httpDate).string(from: expires))))
//        }
//        if let grantFullControl = grantFullControl {
//            items.add(Header(name: "x-amz-grant-full-control", value: String(grantFullControl)))
//        }
//        if let grantRead = grantRead {
//            items.add(Header(name: "x-amz-grant-read", value: String(grantRead)))
//        }
//        if let grantReadACP = grantReadACP {
//            items.add(Header(name: "x-amz-grant-read-acp", value: String(grantReadACP)))
//        }
//        if let grantWriteACP = grantWriteACP {
//            items.add(Header(name: "x-amz-grant-write-acp", value: String(grantWriteACP)))
//        }
//        if let objectLockLegalHoldStatus = objectLockLegalHoldStatus {
//            items.add(Header(name: "x-amz-object-lock-legal-hold", value: String(objectLockLegalHoldStatus.rawValue)))
//        }
//        if let objectLockMode = objectLockMode {
//            items.add(Header(name: "x-amz-object-lock-mode", value: String(objectLockMode.rawValue)))
//        }
//        if let objectLockRetainUntilDate = objectLockRetainUntilDate {
//            items.add(Header(name: "x-amz-object-lock-retain-until-date", value: String(TimestampFormatter(format: .dateTime).string(from: objectLockRetainUntilDate))))
//        }
//        if let requestPayer = requestPayer {
//            items.add(Header(name: "x-amz-request-payer", value: String(requestPayer.rawValue)))
//        }
//        if let sseCustomerAlgorithm = sseCustomerAlgorithm {
//            items.add(Header(name: "x-amz-server-side-encryption-customer-algorithm", value: String(sseCustomerAlgorithm)))
//        }
//        if let sseCustomerKey = sseCustomerKey {
//            items.add(Header(name: "x-amz-server-side-encryption-customer-key", value: String(sseCustomerKey)))
//        }
//        if let sseCustomerKeyMD5 = sseCustomerKeyMD5 {
//            items.add(Header(name: "x-amz-server-side-encryption-customer-key-MD5", value: String(sseCustomerKeyMD5)))
//        }
//        if let ssekmsEncryptionContext = ssekmsEncryptionContext {
//            items.add(Header(name: "x-amz-server-side-encryption-context", value: String(ssekmsEncryptionContext)))
//        }
//        if let ssekmsKeyId = ssekmsKeyId {
//            items.add(Header(name: "x-amz-server-side-encryption-aws-kms-key-id", value: String(ssekmsKeyId)))
//        }
//        if let serverSideEncryption = serverSideEncryption {
//            items.add(Header(name: "x-amz-server-side-encryption", value: String(serverSideEncryption.rawValue)))
//        }
//        if let storageClass = storageClass {
//            items.add(Header(name: "x-amz-storage-class", value: String(storageClass.rawValue)))
//        }
//        if let tagging = tagging {
//            items.add(Header(name: "x-amz-tagging", value: String(tagging)))
//        }
//        if let websiteRedirectLocation = websiteRedirectLocation {
//            items.add(Header(name: "x-amz-website-redirect-location", value: String(websiteRedirectLocation)))
//        }
//        if let metadata = metadata {
//            for (prefixHeaderMapKey, prefixHeaderMapValue) in metadata {
//                items.add(Header(name: "x-amz-meta-\(prefixHeaderMapKey)", value: String(prefixHeaderMapValue)))
//            }
//        }
//        return items
//    }
}

struct CreateMultipartUploadInput: Equatable {
    /// The canned ACL to apply to the object. This action is not supported by Amazon S3 on Outposts.
    var acl: S3ClientTypes.ObjectCannedACL?
    /// The name of the bucket to which to initiate the upload When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// Specifies whether Amazon S3 should use an S3 Bucket Key for object encryption with server-side encryption using Key Management Service (KMS) keys (SSE-KMS). Setting this header to true causes Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS. Specifying this header with an object action doesn’t affect bucket-level settings for S3 Bucket Key.
    var bucketKeyEnabled: Bool?
    /// Specifies caching behavior along the request/reply chain.
    var cacheControl: String?
    /// Indicates the algorithm you want Amazon S3 to use to create the checksum for the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    /// Specifies presentational information for the object.
    var contentDisposition: String?
    /// Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
    var contentEncoding: String?
    /// The language the content is in.
    var contentLanguage: String?
    /// A standard MIME type describing the format of the object data.
    var contentType: String?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// The date and time at which the object is no longer cacheable.
    var expires: Date?
    /// Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object. This action is not supported by Amazon S3 on Outposts.
    var grantFullControl: String?
    /// Allows grantee to read the object data and its metadata. This action is not supported by Amazon S3 on Outposts.
    var grantRead: String?
    /// Allows grantee to read the object ACL. This action is not supported by Amazon S3 on Outposts.
    var grantReadACP: String?
    /// Allows grantee to write the ACL for the applicable object. This action is not supported by Amazon S3 on Outposts.
    var grantWriteACP: String?
    /// Object key for which the multipart upload is to be initiated.
    /// This member is required.
    var key: String?
    /// A map of metadata to store with the object in S3.
    var metadata: [String:String]?
    /// Specifies whether you want to apply a legal hold to the uploaded object.
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    /// Specifies the Object Lock mode that you want to apply to the uploaded object.
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    /// Specifies the date and time when you want the Object Lock to expire.
    var objectLockRetainUntilDate: Date?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// Specifies the algorithm to use to when encrypting the object (for example, AES256).
    var sseCustomerAlgorithm: String?
    /// Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side-encryption-customer-algorithm header.
    var sseCustomerKey: String?
    /// Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
    var sseCustomerKeyMD5: String?
    /// Specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
    var ssekmsEncryptionContext: String?
    /// Specifies the ID (Key ID, Key ARN, or Key Alias) of the symmetric encryption customer managed key to use for object encryption. All GET and PUT requests for an object protected by KMS will fail if they're not made via SSL or using SigV4. For information about configuring any of the officially supported Amazon Web Services SDKs and Amazon Web Services CLI, see [Specifying the Signature Version in Request Authentication](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version) in the Amazon S3 User Guide.
    var ssekmsKeyId: String?
    /// By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see [Storage Classes](https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html) in the Amazon S3 User Guide.
    var storageClass: S3ClientTypes.StorageClass?
    /// The tag-set for the object. The tag-set must be encoded as URL Query parameters.
    var tagging: String?
    /// If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
    var websiteRedirectLocation: String?

    init(
        acl: S3ClientTypes.ObjectCannedACL? = nil,
        bucket: String? = nil,
        bucketKeyEnabled: Bool? = nil,
        cacheControl: String? = nil,
        checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm? = nil,
        contentDisposition: String? = nil,
        contentEncoding: String? = nil,
        contentLanguage: String? = nil,
        contentType: String? = nil,
        expectedBucketOwner: String? = nil,
        expires: Date? = nil,
        grantFullControl: String? = nil,
        grantRead: String? = nil,
        grantReadACP: String? = nil,
        grantWriteACP: String? = nil,
        key: String? = nil,
        metadata: [String:String]? = nil,
        objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus? = nil,
        objectLockMode: S3ClientTypes.ObjectLockMode? = nil,
        objectLockRetainUntilDate: Date? = nil,
        requestPayer: S3ClientTypes.RequestPayer? = nil,
        serverSideEncryption: S3ClientTypes.ServerSideEncryption? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKey: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        ssekmsEncryptionContext: String? = nil,
        ssekmsKeyId: String? = nil,
        storageClass: S3ClientTypes.StorageClass? = nil,
        tagging: String? = nil,
        websiteRedirectLocation: String? = nil
    )
    {
        self.acl = acl
        self.bucket = bucket
        self.bucketKeyEnabled = bucketKeyEnabled
        self.cacheControl = cacheControl
        self.checksumAlgorithm = checksumAlgorithm
        self.contentDisposition = contentDisposition
        self.contentEncoding = contentEncoding
        self.contentLanguage = contentLanguage
        self.contentType = contentType
        self.expectedBucketOwner = expectedBucketOwner
        self.expires = expires
        self.grantFullControl = grantFullControl
        self.grantRead = grantRead
        self.grantReadACP = grantReadACP
        self.grantWriteACP = grantWriteACP
        self.key = key
        self.metadata = metadata
        self.objectLockLegalHoldStatus = objectLockLegalHoldStatus
        self.objectLockMode = objectLockMode
        self.objectLockRetainUntilDate = objectLockRetainUntilDate
        self.requestPayer = requestPayer
        self.serverSideEncryption = serverSideEncryption
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKey = sseCustomerKey
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.ssekmsEncryptionContext = ssekmsEncryptionContext
        self.ssekmsKeyId = ssekmsKeyId
        self.storageClass = storageClass
        self.tagging = tagging
        self.websiteRedirectLocation = websiteRedirectLocation
    }
}


struct CreateMultipartUploadOutputResponse: Equatable {
    /// If the bucket has a lifecycle rule configured with an action to abort incomplete multipart uploads and the prefix in the lifecycle rule matches the object name in the request, the response includes this header. The header indicates when the initiated multipart upload becomes eligible for an abort operation. For more information, see [ Aborting Incomplete Multipart Uploads Using a Bucket Lifecycle Configuration](https://docs.aws.amazon.com/AmazonS3/latest/dev/mpuoverview.html#mpu-abort-incomplete-mpu-lifecycle-config). The response also includes the x-amz-abort-rule-id header that provides the ID of the lifecycle configuration rule that defines this action.
    var abortDate: Date?
    /// This header is returned along with the x-amz-abort-date header. It identifies the applicable lifecycle configuration rule that defines the action to abort incomplete multipart uploads.
    var abortRuleId: String?
    /// The name of the bucket to which the multipart upload was initiated. Does not return the access point ARN or access point alias if used. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    var bucket: String?
    /// Indicates whether the multipart upload uses an S3 Bucket Key for server-side encryption with Key Management Service (KMS) keys (SSE-KMS).
    var bucketKeyEnabled: Bool
    /// The algorithm that was used to create a checksum of the object.
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    /// Object key for which the multipart upload was initiated.
    var key: String?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header confirming the encryption algorithm used.
    var sseCustomerAlgorithm: String?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header to provide round-trip message integrity verification of the customer-provided encryption key.
    var sseCustomerKeyMD5: String?
    /// If present, specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs.
    var ssekmsEncryptionContext: String?
    /// If present, specifies the ID of the Key Management Service (KMS) symmetric encryption customer managed key that was used for the object.
    var ssekmsKeyId: String?
    /// ID for the initiated multipart upload.
    var uploadId: String?

    init(
        abortDate: Date? = nil,
        abortRuleId: String? = nil,
        bucket: String? = nil,
        bucketKeyEnabled: Bool = false,
        checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm? = nil,
        key: String? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        serverSideEncryption: S3ClientTypes.ServerSideEncryption? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        ssekmsEncryptionContext: String? = nil,
        ssekmsKeyId: String? = nil,
        uploadId: String? = nil
    )
    {
        self.abortDate = abortDate
        self.abortRuleId = abortRuleId
        self.bucket = bucket
        self.bucketKeyEnabled = bucketKeyEnabled
        self.checksumAlgorithm = checksumAlgorithm
        self.key = key
        self.requestCharged = requestCharged
        self.serverSideEncryption = serverSideEncryption
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.ssekmsEncryptionContext = ssekmsEncryptionContext
        self.ssekmsKeyId = ssekmsKeyId
        self.uploadId = uploadId
    }

    enum CodingKeys: String, CodingKey {
        case bucket = "Bucket"
        case key = "Key"
        case uploadId = "UploadId"
    }
}
