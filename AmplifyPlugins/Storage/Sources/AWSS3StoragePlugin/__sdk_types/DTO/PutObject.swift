//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension PutObjectInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

struct PutObjectInput: Equatable {
    /// The canned ACL to apply to the object. For more information, see [Canned ACL](https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#CannedACL). This action is not supported by Amazon S3 on Outposts.
    var acl: S3ClientTypes.ObjectCannedACL?
    /// Object data.
    var body: Data?
    /// The bucket name to which the PUT action was initiated. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// Specifies whether Amazon S3 should use an S3 Bucket Key for object encryption with server-side encryption using Key Management Service (KMS) keys (SSE-KMS). Setting this header to true causes Amazon S3 to use an S3 Bucket Key for object encryption with SSE-KMS. Specifying this header with a PUT action doesn’t affect bucket-level settings for S3 Bucket Key.
    var bucketKeyEnabled: Bool?
    /// Can be used to specify caching behavior along the request/reply chain. For more information, see [http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.9).
    var cacheControl: String?
    /// Indicates the algorithm used to create the checksum for the object when using the SDK. This header will not provide any additional functionality if not using the SDK. When sending this header, there must be a corresponding x-amz-checksum or x-amz-trailer header sent. Otherwise, Amazon S3 fails the request with the HTTP status code 400 Bad Request. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide. If you provide an individual checksum, Amazon S3 ignores any provided ChecksumAlgorithm parameter.
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32 checksum of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumCRC32: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 32-bit CRC32C checksum of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumCRC32C: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 160-bit SHA-1 digest of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumSHA1: String?
    /// This header can be used as a data integrity check to verify that the data received is the same data that was originally sent. This header specifies the base64-encoded, 256-bit SHA-256 digest of the object. For more information, see [Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html) in the Amazon S3 User Guide.
    var checksumSHA256: String?
    /// Specifies presentational information for the object. For more information, see [https://www.rfc-editor.org/rfc/rfc6266#section-4](https://www.rfc-editor.org/rfc/rfc6266#section-4).
    var contentDisposition: String?
    /// Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field. For more information, see [https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding](https://www.rfc-editor.org/rfc/rfc9110.html#field.content-encoding).
    var contentEncoding: String?
    /// The language the content is in.
    var contentLanguage: String?
    /// Size of the body in bytes. This parameter is useful when the size of the body cannot be determined automatically. For more information, see [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length](https://www.rfc-editor.org/rfc/rfc9110.html#name-content-length).
    var contentLength: Int?
    /// The base64-encoded 128-bit MD5 digest of the message (without the headers) according to RFC 1864. This header can be used as a message integrity check to verify that the data is the same data that was originally sent. Although it is optional, we recommend using the Content-MD5 mechanism as an end-to-end integrity check. For more information about REST request authentication, see [REST Authentication](https://docs.aws.amazon.com/AmazonS3/latest/dev/RESTAuthentication.html).
    var contentMD5: String?
    /// A standard MIME type describing the format of the contents. For more information, see [https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type](https://www.rfc-editor.org/rfc/rfc9110.html#name-content-type).
    var contentType: String?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// The date and time at which the object is no longer cacheable. For more information, see [https://www.rfc-editor.org/rfc/rfc7234#section-5.3](https://www.rfc-editor.org/rfc/rfc7234#section-5.3).
    var expires: Date?
    /// Gives the grantee READ, READ_ACP, and WRITE_ACP permissions on the object. This action is not supported by Amazon S3 on Outposts.
    var grantFullControl: String?
    /// Allows grantee to read the object data and its metadata. This action is not supported by Amazon S3 on Outposts.
    var grantRead: String?
    /// Allows grantee to read the object ACL. This action is not supported by Amazon S3 on Outposts.
    var grantReadACP: String?
    /// Allows grantee to write the ACL for the applicable object. This action is not supported by Amazon S3 on Outposts.
    var grantWriteACP: String?
    /// Object key for which the PUT action was initiated.
    /// This member is required.
    var key: String?
    /// A map of metadata to store with the object in S3.
    var metadata: [String:String]?
    /// Specifies whether a legal hold will be applied to this object. For more information about S3 Object Lock, see [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html).
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    /// The Object Lock mode that you want to apply to this object.
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    /// The date and time when you want this object's Object Lock to expire. Must be formatted as a timestamp parameter.
    var objectLockRetainUntilDate: Date?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms, aws:kms:dsse).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// Specifies the algorithm to use to when encrypting the object (for example, AES256).
    var sseCustomerAlgorithm: String?
    /// Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side-encryption-customer-algorithm header.
    var sseCustomerKey: String?
    /// Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
    var sseCustomerKeyMD5: String?
    /// Specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs. This value is stored as object metadata and automatically gets passed on to Amazon Web Services KMS for future GetObject or CopyObject operations on this object.
    var ssekmsEncryptionContext: String?
    /// If x-amz-server-side-encryption has a valid value of aws:kms or aws:kms:dsse, this header specifies the ID (Key ID, Key ARN, or Key Alias) of the Key Management Service (KMS) symmetric encryption customer managed key that was used for the object. If you specify x-amz-server-side-encryption:aws:kms or x-amz-server-side-encryption:aws:kms:dsse, but do not provide x-amz-server-side-encryption-aws-kms-key-id, Amazon S3 uses the Amazon Web Services managed key (aws/s3) to protect the data. If the KMS key does not exist in the same account that's issuing the command, you must use the full ARN and not just the ID.
    var ssekmsKeyId: String?
    /// By default, Amazon S3 uses the STANDARD Storage Class to store newly created objects. The STANDARD storage class provides high durability and high availability. Depending on performance needs, you can specify a different Storage Class. Amazon S3 on Outposts only uses the OUTPOSTS Storage Class. For more information, see [Storage Classes](https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html) in the Amazon S3 User Guide.
    var storageClass: S3ClientTypes.StorageClass?
    /// The tag-set for the object. The tag-set must be encoded as URL Query parameters. (For example, "Key1=Value1")
    var tagging: String?
    /// If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata. For information about object metadata, see [Object Key and Metadata](https://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html). In the following example, the request header sets the redirect to an object (anotherPage.html) in the same bucket: x-amz-website-redirect-location: /anotherPage.html In the following example, the request header sets the object redirect to another website: x-amz-website-redirect-location: http://www.example.com/ For more information about website hosting in Amazon S3, see [Hosting Websites on Amazon S3](https://docs.aws.amazon.com/AmazonS3/latest/dev/WebsiteHosting.html) and [How to Configure Website Page Redirects](https://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html).
    var websiteRedirectLocation: String?

    init(
        acl: S3ClientTypes.ObjectCannedACL? = nil,
        body: Data? = nil,
        bucket: String? = nil,
        bucketKeyEnabled: Bool? = nil,
        cacheControl: String? = nil,
        checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm? = nil,
        checksumCRC32: String? = nil,
        checksumCRC32C: String? = nil,
        checksumSHA1: String? = nil,
        checksumSHA256: String? = nil,
        contentDisposition: String? = nil,
        contentEncoding: String? = nil,
        contentLanguage: String? = nil,
        contentLength: Int? = nil,
        contentMD5: String? = nil,
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
        self.body = body
        self.bucket = bucket
        self.bucketKeyEnabled = bucketKeyEnabled
        self.cacheControl = cacheControl
        self.checksumAlgorithm = checksumAlgorithm
        self.checksumCRC32 = checksumCRC32
        self.checksumCRC32C = checksumCRC32C
        self.checksumSHA1 = checksumSHA1
        self.checksumSHA256 = checksumSHA256
        self.contentDisposition = contentDisposition
        self.contentEncoding = contentEncoding
        self.contentLanguage = contentLanguage
        self.contentLength = contentLength
        self.contentMD5 = contentMD5
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

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }
}


struct PutObjectOutputResponse: Equatable {
    /// Indicates whether the uploaded object uses an S3 Bucket Key for server-side encryption with Key Management Service (KMS) keys (SSE-KMS).
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
    /// If the expiration is configured for the object (see [PutBucketLifecycleConfiguration](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutBucketLifecycleConfiguration.html)), the response includes this header. It includes the expiry-date and rule-id key-value pairs that provide information about object expiration. The value of the rule-id is URL-encoded.
    var expiration: String?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms, aws:kms:dsse).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header confirming the encryption algorithm used.
    var sseCustomerAlgorithm: String?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header to provide round-trip message integrity verification of the customer-provided encryption key.
    var sseCustomerKeyMD5: String?
    /// If present, specifies the Amazon Web Services KMS Encryption Context to use for object encryption. The value of this header is a base64-encoded UTF-8 string holding JSON with the encryption context key-value pairs. This value is stored as object metadata and automatically gets passed on to Amazon Web Services KMS for future GetObject or CopyObject operations on this object.
    var ssekmsEncryptionContext: String?
    /// If x-amz-server-side-encryption has a valid value of aws:kms or aws:kms:dsse, this header specifies the ID of the Key Management Service (KMS) symmetric encryption customer managed key that was used for the object.
    var ssekmsKeyId: String?
    /// Version of the object.
    var versionId: String?

    init(
        bucketKeyEnabled: Bool = false,
        checksumCRC32: String? = nil,
        checksumCRC32C: String? = nil,
        checksumSHA1: String? = nil,
        checksumSHA256: String? = nil,
        eTag: String? = nil,
        expiration: String? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        serverSideEncryption: S3ClientTypes.ServerSideEncryption? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        ssekmsEncryptionContext: String? = nil,
        ssekmsKeyId: String? = nil,
        versionId: String? = nil
    )
    {
        self.bucketKeyEnabled = bucketKeyEnabled
        self.checksumCRC32 = checksumCRC32
        self.checksumCRC32C = checksumCRC32C
        self.checksumSHA1 = checksumSHA1
        self.checksumSHA256 = checksumSHA256
        self.eTag = eTag
        self.expiration = expiration
        self.requestCharged = requestCharged
        self.serverSideEncryption = serverSideEncryption
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.ssekmsEncryptionContext = ssekmsEncryptionContext
        self.ssekmsKeyId = ssekmsKeyId
        self.versionId = versionId
    }
}


/*
 extension PutObjectInput {
     func presignURL(config: S3Client.S3ClientConfiguration, expiration: Foundation.TimeInterval) async throws -> ClientRuntime.URL? {
         let serviceName = "S3"
         let input = self
         let encoder = ClientRuntime.XMLEncoder()
         encoder.dateEncodingStrategy = .secondsSince1970
         encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
         let decoder = ClientRuntime.XMLDecoder()
         decoder.dateDecodingStrategy = .secondsSince1970
         decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
         decoder.trimValueWhitespaces = false
         decoder.removeWhitespaceElements = true
         let context = ClientRuntime.HttpContextBuilder()
                       .withEncoder(value: encoder)
                       .withDecoder(value: decoder)
                       .withMethod(value: .put)
                       .withServiceName(value: serviceName)
                       .withOperation(value: "putObject")
                       .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                       .withLogger(value: config.logger)
                       .withPartitionID(value: config.partitionID)
                       .withCredentialsProvider(value: config.credentialsProvider)
                       .withRegion(value: config.region)
                       .withSigningName(value: "s3")
                       .withSigningRegion(value: config.signingRegion)
                       .build()
         var operation = ClientRuntime.OperationStack<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>(id: "putObject")
         operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLPathMiddleware<PutObjectInput, PutObjectOutputResponse, PutObjectOutputError>())
         operation.initializeStep.intercept(position: .after, middleware: ClientRuntime.URLHostMiddleware<PutObjectInput, PutObjectOutputResponse>())
         let endpointParams = EndpointParams(accelerate: config.serviceSpecific.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.serviceSpecific.disableMultiRegionAccessPoints ?? false, endpoint: config.endpoint, forcePathStyle: config.serviceSpecific.forcePathStyle ?? false, region: config.region, useArnRegion: config.serviceSpecific.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.serviceSpecific.useGlobalEndpoint ?? false)
         operation.buildStep.intercept(position: .before, middleware: EndpointResolverMiddleware<PutObjectOutputResponse, PutObjectOutputError>(endpointResolver: config.serviceSpecific.endpointResolver, endpointParams: endpointParams))
         operation.serializeStep.intercept(position: .after, middleware: PutObjectPresignedURLMiddleware())
         operation.finalizeStep.intercept(position: .after, middleware: ClientRuntime.RetryMiddleware<ClientRuntime.DefaultRetryStrategy, AWSClientRuntime.AWSRetryErrorInfoProvider, PutObjectOutputResponse, PutObjectOutputError>(options: config.retryStrategyOptions))
         let sigv4Config = AWSClientRuntime.SigV4Config(signatureType: .requestQueryParams, useDoubleURIEncode: false, shouldNormalizeURIPath: false, expiration: expiration, unsignedBody: true, signingAlgorithm: .sigv4)
         operation.finalizeStep.intercept(position: .before, middleware: AWSClientRuntime.SigV4Middleware<PutObjectOutputResponse, PutObjectOutputError>(config: sigv4Config))
         operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.DeserializeMiddleware<PutObjectOutputResponse, PutObjectOutputError>())
         operation.deserializeStep.intercept(position: .after, middleware: ClientRuntime.LoggerMiddleware<PutObjectOutputResponse, PutObjectOutputError>(clientLogMode: config.clientLogMode))
         let presignedRequestBuilder = try await operation.presignedRequest(context: context, input: input, next: ClientRuntime.NoopHandler())
         guard let builtRequest = presignedRequestBuilder?.build(), let presignedURL = builtRequest.endpoint.url else {
             return nil
         }
         return presignedURL
     }
 }
 */


/*
 extension PutObjectOutputResponse: ClientRuntime.HttpResponseBinding {
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
         if let expirationHeaderValue = httpResponse.headers.value(for: "x-amz-expiration") {
             self.expiration = expirationHeaderValue
         } else {
             self.expiration = nil
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
         if let ssekmsEncryptionContextHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-context") {
             self.ssekmsEncryptionContext = ssekmsEncryptionContextHeaderValue
         } else {
             self.ssekmsEncryptionContext = nil
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
         if let versionIdHeaderValue = httpResponse.headers.value(for: "x-amz-version-id") {
             self.versionId = versionIdHeaderValue
         } else {
             self.versionId = nil
         }
     }
 }
 */
