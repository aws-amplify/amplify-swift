//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation


extension UploadPartInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

struct UploadPartInput: Equatable {
    /// Object data.
    var body: Data?
    /// The name of the bucket to which the multipart upload was initiated. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding x-amz-checksum or x-amz-trailer header sent. Otherwise, Amazon S3 fails the request with the HTTP status code 400 Bad Request. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide. If you provide an individual checksum, Amazon S3 ignores any provided ChecksumAlgorithm parameter. This checksum algorithm must be the same for all parts and it match the checksum value supplied in the CreateMultipartUpload request.
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumCRC32: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32C checksum of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumCRC32C: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 160-bit SHA-1 digest of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumSHA1: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumSHA256: String?
    /// Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically.
    var contentLength: Int?
    /// The base64-encoded 128-bit MD5 digest of the part data. This parameter is auto-populated when using the command from the CLI. This parameter is required if object lock parameters are specified.
    var contentMD5: String?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// Object key for which the multipart upload was initiated.
    /// This member is required.
    var key: String?
    /// Part number of part being uploaded. This is a positive integer between 1 and 10,000.
    /// This member is required.
    var partNumber: Int?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// Specifies the algorithm to use to when encrypting the object (for example, AES256).
    var sseCustomerAlgorithm: String?
    /// Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side-encryption-customer-algorithm header. This must be the same encryption key specified in the initiate multipart upload request.
    var sseCustomerKey: String?
    /// Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
    var sseCustomerKeyMD5: String?
    /// Upload ID identifying the multipart upload whose part is being uploaded.
    /// This member is required.
    var uploadId: String?

    init(
        body: Data? = nil,
        bucket: String? = nil,
        checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm? = nil,
        checksumCRC32: String? = nil,
        checksumCRC32C: String? = nil,
        checksumSHA1: String? = nil,
        checksumSHA256: String? = nil,
        contentLength: Int? = nil,
        contentMD5: String? = nil,
        expectedBucketOwner: String? = nil,
        key: String? = nil,
        partNumber: Int? = nil,
        requestPayer: S3ClientTypes.RequestPayer? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKey: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        uploadId: String? = nil
    )
    {
        self.body = body
        self.bucket = bucket
        self.checksumAlgorithm = checksumAlgorithm
        self.checksumCRC32 = checksumCRC32
        self.checksumCRC32C = checksumCRC32C
        self.checksumSHA1 = checksumSHA1
        self.checksumSHA256 = checksumSHA256
        self.contentLength = contentLength
        self.contentMD5 = contentMD5
        self.expectedBucketOwner = expectedBucketOwner
        self.key = key
        self.partNumber = partNumber
        self.requestPayer = requestPayer
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKey = sseCustomerKey
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.uploadId = uploadId
    }

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }

}

struct UploadPartOutputResponse: Equatable {
    /// Indicates whether the multipart upload uses an S3 Bucket Key for server-side encryption with Key Management Service (KMS) keys (SSE-KMS).
    var bucketKeyEnabled: Bool
    /// The base64-encoded, 32-bit CRC32 checksum of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumCRC32: String?
    /// The base64-encoded, 32-bit CRC32C checksum of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumCRC32C: String?
    /// The base64-encoded, 160-bit SHA-1 digest of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumSHA1: String?
    /// The base64-encoded, 256-bit SHA-256 digest of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumSHA256: String?
    /// Entity tag for the uploaded object.
    var eTag: String?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header confirming the encryption algorithm used.
    var sseCustomerAlgorithm: String?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header to provide round-trip message integrity verification of the customer-provided encryption key.
    var sseCustomerKeyMD5: String?
    /// If present, specifies the ID of the Key Management Service (KMS) symmetric encryption customer managed key was used for the object.
    var ssekmsKeyId: String?

    init(
        bucketKeyEnabled: Bool = false,
        checksumCRC32: String? = nil,
        checksumCRC32C: String? = nil,
        checksumSHA1: String? = nil,
        checksumSHA256: String? = nil,
        eTag: String? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        serverSideEncryption: S3ClientTypes.ServerSideEncryption? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        ssekmsKeyId: String? = nil
    )
    {
        self.bucketKeyEnabled = bucketKeyEnabled
        self.checksumCRC32 = checksumCRC32
        self.checksumCRC32C = checksumCRC32C
        self.checksumSHA1 = checksumSHA1
        self.checksumSHA256 = checksumSHA256
        self.eTag = eTag
        self.requestCharged = requestCharged
        self.serverSideEncryption = serverSideEncryption
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.ssekmsKeyId = ssekmsKeyId
    }
}


/*
 extension UploadPartOutputResponse: ClientRuntime.HttpResponseBinding {
     init(httpResponse: ClientRuntime.HttpResponse, decoder: ClientRuntime.ResponseDecoder? = nil) async throws {
         if let bucketKeyEnabledHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-bucket-key-enabled") {
             self.bucketKeyEnabled = Bool(bucketKeyEnabledHeaderValue) ?? false
         } else {
             self.bucketKeyEnabled = false
         }
         if let checksumCRC32HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-crc32") {
             self.checksumCRC32 = checksumCRC32HeaderValue
         } else {
             self.checksumCRC32 = nil
         }
         if let checksumCRC32CHeaderValue = httpResponse.headers.value(for: "x-amz-checksum-crc32c") {
             self.checksumCRC32C = checksumCRC32CHeaderValue
         } else {
             self.checksumCRC32C = nil
         }
         if let checksumSHA1HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-sha1") {
             self.checksumSHA1 = checksumSHA1HeaderValue
         } else {
             self.checksumSHA1 = nil
         }
         if let checksumSHA256HeaderValue = httpResponse.headers.value(for: "x-amz-checksum-sha256") {
             self.checksumSHA256 = checksumSHA256HeaderValue
         } else {
             self.checksumSHA256 = nil
         }
         if let eTagHeaderValue = httpResponse.headers.value(for: "ETag") {
             self.eTag = eTagHeaderValue
         } else {
             self.eTag = nil
         }
         if let requestChargedHeaderValue = httpResponse.headers.value(for: "x-amz-request-charged") {
             self.requestCharged = S3ClientTypes.RequestCharged(rawValue: requestChargedHeaderValue)
         } else {
             self.requestCharged = nil
         }
         if let sseCustomerAlgorithmHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-customer-algorithm") {
             self.sseCustomerAlgorithm = sseCustomerAlgorithmHeaderValue
         } else {
             self.sseCustomerAlgorithm = nil
         }
         if let sseCustomerKeyMD5HeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-customer-key-MD5") {
             self.sseCustomerKeyMD5 = sseCustomerKeyMD5HeaderValue
         } else {
             self.sseCustomerKeyMD5 = nil
         }
         if let ssekmsKeyIdHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-aws-kms-key-id") {
             self.ssekmsKeyId = ssekmsKeyIdHeaderValue
         } else {
             self.ssekmsKeyId = nil
         }
         if let serverSideEncryptionHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption") {
             self.serverSideEncryption = S3ClientTypes.ServerSideEncryption(rawValue: serverSideEncryptionHeaderValue)
         } else {
             self.serverSideEncryption = nil
         }
     }
 }

 */
