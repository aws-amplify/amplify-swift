//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

extension GetObjectInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

struct GetObjectInput: Equatable {
    /// The bucket name containing the object. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When using an Object Lambda access point the hostname takes the form AccessPointName-AccountId.s3-object-lambda.Region.amazonaws.com. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// To retrieve the checksum, this mode must be enabled.
    var checksumMode: S3ClientTypes.ChecksumMode?
    /// The account ID of the expected bucket owner. If the bucket is owned by a different account, the request fails with the HTTP status code 403 Forbidden (access denied).
    var expectedBucketOwner: String?
    /// Return the object only if its entity tag (ETag) is the same as the one specified; otherwise, return a 412 (precondition failed) error.
    var ifMatch: String?
    /// Return the object only if it has been modified since the specified time; otherwise, return a 304 (not modified) error.
    var ifModifiedSince: Date?
    /// Return the object only if its entity tag (ETag) is different from the one specified; otherwise, return a 304 (not modified) error.
    var ifNoneMatch: String?
    /// Return the object only if it has not been modified since the specified time; otherwise, return a 412 (precondition failed) error.
    var ifUnmodifiedSince: Date?
    /// Key of the object to get.
    /// This member is required.
    var key: String?
    /// Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' GET request for the part specified. Useful for downloading just a part of an object.
    var partNumber: Int?
    /// Downloads the specified range bytes of an object. For more information about the HTTP Range header, see [https://www.rfc-editor.org/rfc/rfc9110.html#name-range](https://www.rfc-editor.org/rfc/rfc9110.html#name-range). Amazon S3 doesn't support retrieving multiple ranges of data per GET request.
    var range: String?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// Sets the Cache-Control header of the response.
    var responseCacheControl: String?
    /// Sets the Content-Disposition header of the response
    var responseContentDisposition: String?
    /// Sets the Content-Encoding header of the response.
    var responseContentEncoding: String?
    /// Sets the Content-Language header of the response.
    var responseContentLanguage: String?
    /// Sets the Content-Type header of the response.
    var responseContentType: String?
    /// Sets the Expires header of the response.
    var responseExpires: Date?
    /// Specifies the algorithm to use to when decrypting the object (for example, AES256).
    var sseCustomerAlgorithm: String?
    /// Specifies the customer-provided encryption key for Amazon S3 used to encrypt the data. This value is used to decrypt the object when recovering it and must match the one used when storing the data. The key must be appropriate for use with the algorithm specified in the x-amz-server-side-encryption-customer-algorithm header.
    var sseCustomerKey: String?
    /// Specifies the 128-bit MD5 digest of the encryption key according to RFC 1321. Amazon S3 uses this header for a message integrity check to ensure that the encryption key was transmitted without error.
    var sseCustomerKeyMD5: String?
    /// VersionId used to reference a specific version of the object.
    var versionId: String?

    init(
        bucket: String? = nil,
        checksumMode: S3ClientTypes.ChecksumMode? = nil,
        expectedBucketOwner: String? = nil,
        ifMatch: String? = nil,
        ifModifiedSince: Date? = nil,
        ifNoneMatch: String? = nil,
        ifUnmodifiedSince: Date? = nil,
        key: String? = nil,
        partNumber: Int? = nil,
        range: String? = nil,
        requestPayer: S3ClientTypes.RequestPayer? = nil,
        responseCacheControl: String? = nil,
        responseContentDisposition: String? = nil,
        responseContentEncoding: String? = nil,
        responseContentLanguage: String? = nil,
        responseContentType: String? = nil,
        responseExpires: Date? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKey: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        versionId: String? = nil
    )
    {
        self.bucket = bucket
        self.checksumMode = checksumMode
        self.expectedBucketOwner = expectedBucketOwner
        self.ifMatch = ifMatch
        self.ifModifiedSince = ifModifiedSince
        self.ifNoneMatch = ifNoneMatch
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.key = key
        self.partNumber = partNumber
        self.range = range
        self.requestPayer = requestPayer
        self.responseCacheControl = responseCacheControl
        self.responseContentDisposition = responseContentDisposition
        self.responseContentEncoding = responseContentEncoding
        self.responseContentLanguage = responseContentLanguage
        self.responseContentType = responseContentType
        self.responseExpires = responseExpires
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKey = sseCustomerKey
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.versionId = versionId
    }
}


struct GetObjectOutputResponse: Equatable {
    /// Indicates that a range of bytes was specified.
    var acceptRanges: String?
    /// Object data.
    var body: Data?
    /// Indicates whether the object uses an S3 Bucket Key for server-side encryption with Key Management Service (KMS) keys (SSE-KMS).
    var bucketKeyEnabled: Bool
    /// Specifies caching behavior along the request/reply chain.
    var cacheControl: String?
    /// The base64-encoded, 32-bit CRC32 checksum of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumCRC32: String?
    /// The base64-encoded, 32-bit CRC32C checksum of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumCRC32C: String?
    /// The base64-encoded, 160-bit SHA-1 digest of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumSHA1: String?
    /// The base64-encoded, 256-bit SHA-256 digest of the object. This will only be present if it was uploaded with the object. With multipart uploads, this may not be a checksum value of the object. For more information about how checksums are calculated with multipart uploads, see [ Checking object integrity](https://docs.aws.amazon.com/AmazonS3/latest/userguide/checking-object-integrity.html#large-object-checksums) in the Amazon S3 User Guide.
    var checksumSHA256: String?
    /// Specifies presentational information for the object.
    var contentDisposition: String?
    /// Specifies what content encodings have been applied to the object and thus what decoding mechanisms must be applied to obtain the media-type referenced by the Content-Type header field.
    var contentEncoding: String?
    /// The language the content is in.
    var contentLanguage: String?
    /// Size of the body in bytes.
    var contentLength: Int
    /// The portion of the object returned in the response.
    var contentRange: String?
    /// A standard MIME type describing the format of the object data.
    var contentType: String?
    /// Specifies whether the object retrieved was (true) or was not (false) a Delete Marker. If false, this response header does not appear in the response.
    var deleteMarker: Bool
    /// An entity tag (ETag) is an opaque identifier assigned by a web server to a specific version of a resource found at a URL.
    var eTag: String?
    /// If the object expiration is configured (see PUT Bucket lifecycle), the response includes this header. It includes the expiry-date and rule-id key-value pairs providing object expiration information. The value of the rule-id is URL-encoded.
    var expiration: String?
    /// The date and time at which the object is no longer cacheable.
    var expires: String?
    /// Creation date of the object.
    var lastModified: Date?
    /// A map of metadata to store with the object in S3.
    var metadata: [String:String]?
    /// This is set to the number of metadata entries not returned in x-amz-meta headers. This can happen if you create metadata using an API like SOAP that supports more flexible metadata than the REST API. For example, using SOAP, you can create metadata whose values are not legal HTTP headers.
    var missingMeta: Int
    /// Indicates whether this object has an active legal hold. This field is only returned if you have permission to view an object's legal hold status.
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    /// The Object Lock mode currently in place for this object.
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    /// The date and time when this object's Object Lock will expire.
    var objectLockRetainUntilDate: Date?
    /// The count of parts this object has. This value is only returned if you specify partNumber in your request and the object was uploaded as a multipart upload.
    var partsCount: Int
    /// Amazon S3 can return this if your request involves a bucket that is either a source or destination in a replication rule.
    var replicationStatus: S3ClientTypes.ReplicationStatus?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// Provides information about object restoration action and expiration time of the restored object copy.
    var restore: String?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms, aws:kms:dsse).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header confirming the encryption algorithm used.
    var sseCustomerAlgorithm: String?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header to provide round-trip message integrity verification of the customer-provided encryption key.
    var sseCustomerKeyMD5: String?
    /// If present, specifies the ID of the Key Management Service (KMS) symmetric encryption customer managed key that was used for the object.
    var ssekmsKeyId: String?
    /// Provides storage class information of the object. Amazon S3 returns this header for all objects except for S3 Standard storage class objects.
    var storageClass: S3ClientTypes.StorageClass?
    /// The number of tags, if any, on the object.
    var tagCount: Int
    /// Version of the object.
    var versionId: String?
    /// If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
    var websiteRedirectLocation: String?

    init(
        acceptRanges: String? = nil,
        body: Data? = nil,
        bucketKeyEnabled: Bool = false,
        cacheControl: String? = nil,
        checksumCRC32: String? = nil,
        checksumCRC32C: String? = nil,
        checksumSHA1: String? = nil,
        checksumSHA256: String? = nil,
        contentDisposition: String? = nil,
        contentEncoding: String? = nil,
        contentLanguage: String? = nil,
        contentLength: Int = 0,
        contentRange: String? = nil,
        contentType: String? = nil,
        deleteMarker: Bool = false,
        eTag: String? = nil,
        expiration: String? = nil,
        expires: String? = nil,
        lastModified: Date? = nil,
        metadata: [String:String]? = nil,
        missingMeta: Int = 0,
        objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus? = nil,
        objectLockMode: S3ClientTypes.ObjectLockMode? = nil,
        objectLockRetainUntilDate: Date? = nil,
        partsCount: Int = 0,
        replicationStatus: S3ClientTypes.ReplicationStatus? = nil,
        requestCharged: S3ClientTypes.RequestCharged? = nil,
        restore: String? = nil,
        serverSideEncryption: S3ClientTypes.ServerSideEncryption? = nil,
        sseCustomerAlgorithm: String? = nil,
        sseCustomerKeyMD5: String? = nil,
        ssekmsKeyId: String? = nil,
        storageClass: S3ClientTypes.StorageClass? = nil,
        tagCount: Int = 0,
        versionId: String? = nil,
        websiteRedirectLocation: String? = nil
    )
    {
        self.acceptRanges = acceptRanges
        self.body = body
        self.bucketKeyEnabled = bucketKeyEnabled
        self.cacheControl = cacheControl
        self.checksumCRC32 = checksumCRC32
        self.checksumCRC32C = checksumCRC32C
        self.checksumSHA1 = checksumSHA1
        self.checksumSHA256 = checksumSHA256
        self.contentDisposition = contentDisposition
        self.contentEncoding = contentEncoding
        self.contentLanguage = contentLanguage
        self.contentLength = contentLength
        self.contentRange = contentRange
        self.contentType = contentType
        self.deleteMarker = deleteMarker
        self.eTag = eTag
        self.expiration = expiration
        self.expires = expires
        self.lastModified = lastModified
        self.metadata = metadata
        self.missingMeta = missingMeta
        self.objectLockLegalHoldStatus = objectLockLegalHoldStatus
        self.objectLockMode = objectLockMode
        self.objectLockRetainUntilDate = objectLockRetainUntilDate
        self.partsCount = partsCount
        self.replicationStatus = replicationStatus
        self.requestCharged = requestCharged
        self.restore = restore
        self.serverSideEncryption = serverSideEncryption
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.ssekmsKeyId = ssekmsKeyId
        self.storageClass = storageClass
        self.tagCount = tagCount
        self.versionId = versionId
        self.websiteRedirectLocation = websiteRedirectLocation
    }

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }
}



/*
 struct GetObjectInputGETQueryItemMiddleware: Middleware {
     let id: String = "GetObjectInputGETQueryItemMiddleware"

     init() {}

     func handle<H>(context: Context,
                   input: SerializeStepInput<GetObjectInput>,
                   next: H) async throws -> OperationOutput<GetObjectOutputResponse>
     where H: Handler,
     Self.MInput == H.Input,
     Self.MOutput == H.Output,
     Self.Context == H.Context
     {
         if let bucket = input.operationInput.bucket {
             let queryItem = URLQueryItem(name: "Bucket".urlPercentEncoding(), value: String(bucket).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let ifMatch = input.operationInput.ifMatch {
             let queryItem = URLQueryItem(name: "IfMatch".urlPercentEncoding(), value: String(ifMatch).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let ifNoneMatch = input.operationInput.ifNoneMatch {
             let queryItem = URLQueryItem(name: "IfNoneMatch".urlPercentEncoding(), value: String(ifNoneMatch).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let key = input.operationInput.key {
             let queryItem = URLQueryItem(name: "Key".urlPercentEncoding(), value: String(key).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let range = input.operationInput.range {
             let queryItem = URLQueryItem(name: "Range".urlPercentEncoding(), value: String(range).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let responseCacheControl = input.operationInput.responseCacheControl {
             let queryItem = URLQueryItem(name: "ResponseCacheControl".urlPercentEncoding(), value: String(responseCacheControl).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let responseContentDisposition = input.operationInput.responseContentDisposition {
             let queryItem = URLQueryItem(name: "ResponseContentDisposition".urlPercentEncoding(), value: String(responseContentDisposition).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let responseContentEncoding = input.operationInput.responseContentEncoding {
             let queryItem = URLQueryItem(name: "ResponseContentEncoding".urlPercentEncoding(), value: String(responseContentEncoding).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let responseContentLanguage = input.operationInput.responseContentLanguage {
             let queryItem = URLQueryItem(name: "ResponseContentLanguage".urlPercentEncoding(), value: String(responseContentLanguage).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let responseContentType = input.operationInput.responseContentType {
             let queryItem = URLQueryItem(name: "ResponseContentType".urlPercentEncoding(), value: String(responseContentType).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let versionId = input.operationInput.versionId {
             let queryItem = URLQueryItem(name: "VersionId".urlPercentEncoding(), value: String(versionId).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let sseCustomerAlgorithm = input.operationInput.sseCustomerAlgorithm {
             let queryItem = URLQueryItem(name: "SSECustomerAlgorithm".urlPercentEncoding(), value: String(sseCustomerAlgorithm).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let sseCustomerKey = input.operationInput.sseCustomerKey {
             let queryItem = URLQueryItem(name: "SSECustomerKey".urlPercentEncoding(), value: String(sseCustomerKey).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let sseCustomerKeyMD5 = input.operationInput.sseCustomerKeyMD5 {
             let queryItem = URLQueryItem(name: "SSECustomerKeyMD5".urlPercentEncoding(), value: String(sseCustomerKeyMD5).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let requestPayer = input.operationInput.requestPayer {
             let queryItem = URLQueryItem(name: "RequestPayer".urlPercentEncoding(), value: String(requestPayer.rawValue).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let expectedBucketOwner = input.operationInput.expectedBucketOwner {
             let queryItem = URLQueryItem(name: "ExpectedBucketOwner".urlPercentEncoding(), value: String(expectedBucketOwner).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         if let checksumMode = input.operationInput.checksumMode {
             let queryItem = URLQueryItem(name: "ChecksumMode".urlPercentEncoding(), value: String(checksumMode.rawValue).urlPercentEncoding())
             input.builder.withQueryItem(queryItem)
         }
         return try await next.handle(context: context, input: input)
     }

     typealias MInput = SerializeStepInput<GetObjectInput>
     typealias MOutput = OperationOutput<GetObjectOutputResponse>
     typealias Context = HttpContext
 }
 */

/*
 extension GetObjectInput: QueryItemProvider {
     var queryItems: [URLQueryItem] {
         get throws {
             var items = [URLQueryItem]()
             items.append(URLQueryItem(name: "x-id", value: "GetObject"))
             if let versionId = versionId {
                 let versionIdQueryItem = URLQueryItem(name: "versionId".urlPercentEncoding(), value: String(versionId).urlPercentEncoding())
                 items.append(versionIdQueryItem)
             }
             if let responseContentDisposition = responseContentDisposition {
                 let responseContentDispositionQueryItem = URLQueryItem(name: "response-content-disposition".urlPercentEncoding(), value: String(responseContentDisposition).urlPercentEncoding())
                 items.append(responseContentDispositionQueryItem)
             }
             if let partNumber = partNumber {
                 let partNumberQueryItem = URLQueryItem(name: "partNumber".urlPercentEncoding(), value: String(partNumber).urlPercentEncoding())
                 items.append(partNumberQueryItem)
             }
             if let responseContentType = responseContentType {
                 let responseContentTypeQueryItem = URLQueryItem(name: "response-content-type".urlPercentEncoding(), value: String(responseContentType).urlPercentEncoding())
                 items.append(responseContentTypeQueryItem)
             }
             if let responseExpires = responseExpires {
                 let responseExpiresQueryItem = URLQueryItem(name: "response-expires".urlPercentEncoding(), value: String(TimestampFormatter(format: .httpDate).string(from: responseExpires)).urlPercentEncoding())
                 items.append(responseExpiresQueryItem)
             }
             if let responseContentEncoding = responseContentEncoding {
                 let responseContentEncodingQueryItem = URLQueryItem(name: "response-content-encoding".urlPercentEncoding(), value: String(responseContentEncoding).urlPercentEncoding())
                 items.append(responseContentEncodingQueryItem)
             }
             if let responseCacheControl = responseCacheControl {
                 let responseCacheControlQueryItem = URLQueryItem(name: "response-cache-control".urlPercentEncoding(), value: String(responseCacheControl).urlPercentEncoding())
                 items.append(responseCacheControlQueryItem)
             }
             if let responseContentLanguage = responseContentLanguage {
                 let responseContentLanguageQueryItem = URLQueryItem(name: "response-content-language".urlPercentEncoding(), value: String(responseContentLanguage).urlPercentEncoding())
                 items.append(responseContentLanguageQueryItem)
             }
             return items
         }
     }
 }
 */

/*
 extension GetObjectInput {
     func presign(config: S3Client.S3ClientConfiguration, expiration: Foundation.TimeInterval) async throws -> SdkHttpRequest? {
         let serviceName = "S3"
         let input = self
         let encoder = XMLEncoder()
         encoder.dateEncodingStrategy = .secondsSince1970
         encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
         let decoder = XMLDecoder()
         decoder.dateDecodingStrategy = .secondsSince1970
         decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
         decoder.trimValueWhitespaces = false
         decoder.removeWhitespaceElements = true
         let context = HttpContextBuilder()
                       .withEncoder(value: encoder)
                       .withDecoder(value: decoder)
                       .withMethod(value: .get)
                       .withServiceName(value: serviceName)
                       .withOperation(value: "getObject")
                       .withIdempotencyTokenGenerator(value: config.idempotencyTokenGenerator)
                       .withLogger(value: config.logger)
                       .withPartitionID(value: config.partitionID)
                       .withCredentialsProvider(value: config.credentialsProvider)
                       .withRegion(value: config.region)
                       .withSigningName(value: "s3")
                       .withSigningRegion(value: config.signingRegion)
                       .build()
         var operation = OperationStack<GetObjectInput, GetObjectOutputResponse, GetObjectOutputError>(id: "getObject")
         operation.initializeStep.intercept(position: .after, middleware: URLPathMiddleware<GetObjectInput, GetObjectOutputResponse, GetObjectOutputError>())
         operation.initializeStep.intercept(position: .after, middleware: URLHostMiddleware<GetObjectInput, GetObjectOutputResponse>())
         let endpointParams = EndpointParams(accelerate: config.serviceSpecific.accelerate ?? false, bucket: input.bucket, disableMultiRegionAccessPoints: config.serviceSpecific.disableMultiRegionAccessPoints ?? false, endpoint: config.endpoint, forcePathStyle: config.serviceSpecific.forcePathStyle ?? false, region: config.region, useArnRegion: config.serviceSpecific.useArnRegion, useDualStack: config.useDualStack ?? false, useFIPS: config.useFIPS ?? false, useGlobalEndpoint: config.serviceSpecific.useGlobalEndpoint ?? false)
         operation.buildStep.intercept(position: .before, middleware: EndpointResolverMiddleware<GetObjectOutputResponse, GetObjectOutputError>(endpointResolver: config.serviceSpecific.endpointResolver, endpointParams: endpointParams))
         operation.buildStep.intercept(position: .before, middleware: AWSUserAgentMiddleware(metadata: AWSAWSUserAgentMetadata.fromConfig(serviceID: serviceName, version: "1.0", config: config)))
         operation.serializeStep.intercept(position: .after, middleware: HeaderMiddleware<GetObjectInput, GetObjectOutputResponse>())
         operation.serializeStep.intercept(position: .after, middleware: QueryItemMiddleware<GetObjectInput, GetObjectOutputResponse>())
         operation.finalizeStep.intercept(position: .after, middleware: RetryMiddleware<DefaultRetryStrategy, AWSAWSRetryErrorInfoProvider, GetObjectOutputResponse, GetObjectOutputError>(options: config.retryStrategyOptions))
         let sigv4Config = AWSSigV4Config(useDoubleURIEncode: false, shouldNormalizeURIPath: false, expiration: expiration, signedBodyHeader: .contentSha256, unsignedBody: false, signingAlgorithm: .sigv4)
         operation.finalizeStep.intercept(position: .before, middleware: AWSSigV4Middleware<GetObjectOutputResponse, GetObjectOutputError>(config: sigv4Config))
         operation.deserializeStep.intercept(position: .after, middleware: DeserializeMiddleware<GetObjectOutputResponse, GetObjectOutputError>())
         operation.deserializeStep.intercept(position: .after, middleware: LoggerMiddleware<GetObjectOutputResponse, GetObjectOutputError>(clientLogMode: config.clientLogMode))
         let presignedRequestBuilder = try await operation.presignedRequest(context: context, input: input, next: NoopHandler())
         guard let builtRequest = presignedRequestBuilder?.build() else {
             return nil
         }
         return builtRequest
     }
 }
 */


/*
 init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) async throws {
     if let acceptRangesHeaderValue = httpResponse.headers.value(for: "accept-ranges") {
         self.acceptRanges = acceptRangesHeaderValue
     } else {
         self.acceptRanges = nil
     }
     if let bucketKeyEnabledHeaderValue = httpResponse.headers.value(for: "x-amz-server-side-encryption-bucket-key-enabled") {
         self.bucketKeyEnabled = Bool(bucketKeyEnabledHeaderValue) ?? false
     } else {
         self.bucketKeyEnabled = false
     }
     if let cacheControlHeaderValue = httpResponse.headers.value(for: "Cache-Control") {
         self.cacheControl = cacheControlHeaderValue
     } else {
         self.cacheControl = nil
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
     if let contentDispositionHeaderValue = httpResponse.headers.value(for: "Content-Disposition") {
         self.contentDisposition = contentDispositionHeaderValue
     } else {
         self.contentDisposition = nil
     }
     if let contentEncodingHeaderValue = httpResponse.headers.value(for: "Content-Encoding") {
         self.contentEncoding = contentEncodingHeaderValue
     } else {
         self.contentEncoding = nil
     }
     if let contentLanguageHeaderValue = httpResponse.headers.value(for: "Content-Language") {
         self.contentLanguage = contentLanguageHeaderValue
     } else {
         self.contentLanguage = nil
     }
     if let contentLengthHeaderValue = httpResponse.headers.value(for: "Content-Length") {
         self.contentLength = Int(contentLengthHeaderValue) ?? 0
     } else {
         self.contentLength = 0
     }
     if let contentRangeHeaderValue = httpResponse.headers.value(for: "Content-Range") {
         self.contentRange = contentRangeHeaderValue
     } else {
         self.contentRange = nil
     }
     if let contentTypeHeaderValue = httpResponse.headers.value(for: "Content-Type") {
         self.contentType = contentTypeHeaderValue
     } else {
         self.contentType = nil
     }
     if let deleteMarkerHeaderValue = httpResponse.headers.value(for: "x-amz-delete-marker") {
         self.deleteMarker = Bool(deleteMarkerHeaderValue) ?? false
     } else {
         self.deleteMarker = false
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
     if let expiresHeaderValue = httpResponse.headers.value(for: "Expires") {
         self.expires = expiresHeaderValue
     } else {
         self.expires = nil
     }
     if let lastModifiedHeaderValue = httpResponse.headers.value(for: "Last-Modified") {
         self.lastModified = TimestampFormatter(format: .httpDate).date(from: lastModifiedHeaderValue)
     } else {
         self.lastModified = nil
     }
     if let missingMetaHeaderValue = httpResponse.headers.value(for: "x-amz-missing-meta") {
         self.missingMeta = Int(missingMetaHeaderValue) ?? 0
     } else {
         self.missingMeta = 0
     }
     if let objectLockLegalHoldStatusHeaderValue = httpResponse.headers.value(for: "x-amz-object-lock-legal-hold") {
         self.objectLockLegalHoldStatus = S3ClientTypes.ObjectLockLegalHoldStatus(rawValue: objectLockLegalHoldStatusHeaderValue)
     } else {
         self.objectLockLegalHoldStatus = nil
     }
     if let objectLockModeHeaderValue = httpResponse.headers.value(for: "x-amz-object-lock-mode") {
         self.objectLockMode = S3ClientTypes.ObjectLockMode(rawValue: objectLockModeHeaderValue)
     } else {
         self.objectLockMode = nil
     }
     if let objectLockRetainUntilDateHeaderValue = httpResponse.headers.value(for: "x-amz-object-lock-retain-until-date") {
         self.objectLockRetainUntilDate = TimestampFormatter(format: .dateTime).date(from: objectLockRetainUntilDateHeaderValue)
     } else {
         self.objectLockRetainUntilDate = nil
     }
     if let partsCountHeaderValue = httpResponse.headers.value(for: "x-amz-mp-parts-count") {
         self.partsCount = Int(partsCountHeaderValue) ?? 0
     } else {
         self.partsCount = 0
     }
     if let replicationStatusHeaderValue = httpResponse.headers.value(for: "x-amz-replication-status") {
         self.replicationStatus = S3ClientTypes.ReplicationStatus(rawValue: replicationStatusHeaderValue)
     } else {
         self.replicationStatus = nil
     }
     if let requestChargedHeaderValue = httpResponse.headers.value(for: "x-amz-request-charged") {
         self.requestCharged = S3ClientTypes.RequestCharged(rawValue: requestChargedHeaderValue)
     } else {
         self.requestCharged = nil
     }
     if let restoreHeaderValue = httpResponse.headers.value(for: "x-amz-restore") {
         self.restore = restoreHeaderValue
     } else {
         self.restore = nil
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
     if let storageClassHeaderValue = httpResponse.headers.value(for: "x-amz-storage-class") {
         self.storageClass = S3ClientTypes.StorageClass(rawValue: storageClassHeaderValue)
     } else {
         self.storageClass = nil
     }
     if let tagCountHeaderValue = httpResponse.headers.value(for: "x-amz-tagging-count") {
         self.tagCount = Int(tagCountHeaderValue) ?? 0
     } else {
         self.tagCount = 0
     }
     if let versionIdHeaderValue = httpResponse.headers.value(for: "x-amz-version-id") {
         self.versionId = versionIdHeaderValue
     } else {
         self.versionId = nil
     }
     if let websiteRedirectLocationHeaderValue = httpResponse.headers.value(for: "x-amz-website-redirect-location") {
         self.websiteRedirectLocation = websiteRedirectLocationHeaderValue
     } else {
         self.websiteRedirectLocation = nil
     }
     let keysForMetadata = httpResponse.headers.dictionary.keys.filter({ $0.starts(with: "x-amz-meta-") })
     if (!keysForMetadata.isEmpty) {
         var mapMember = [String: String]()
         for headerKey in keysForMetadata {
             let mapMemberValue = httpResponse.headers.dictionary[headerKey]?[0]
             let mapMemberKey = headerKey.removePrefix("x-amz-meta-")
             mapMember[mapMemberKey] = mapMemberValue
         }
         self.metadata = mapMember
     } else {
         self.metadata = [:]
     }
     switch httpResponse.body {
     case .data(let data):
         self.body = .data(data)
     case .stream(let stream):
         self.body = .stream(stream)
     case .none:
         self.body = nil
     }
 }
}
 */
