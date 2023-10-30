//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct HeadObjectInput: Equatable {
    /// The name of the bucket containing the object. When using this action with an access point, you must direct requests to the access point hostname. The access point hostname takes the form AccessPointName-AccountId.s3-accesspoint.Region.amazonaws.com. When using this action with an access point through the Amazon Web Services SDKs, you provide the access point ARN in place of the bucket name. For more information about access point ARNs, see [Using access points](https://docs.aws.amazon.com/AmazonS3/latest/userguide/using-access-points.html) in the Amazon S3 User Guide. When you use this action with Amazon S3 on Outposts, you must direct requests to the S3 on Outposts hostname. The S3 on Outposts hostname takes the form  AccessPointName-AccountId.outpostID.s3-outposts.Region.amazonaws.com. When you use this action with S3 on Outposts through the Amazon Web Services SDKs, you provide the Outposts access point ARN in place of the bucket name. For more information about S3 on Outposts ARNs, see [What is S3 on Outposts?](https://docs.aws.amazon.com/AmazonS3/latest/userguide/S3onOutposts.html) in the Amazon S3 User Guide.
    /// This member is required.
    var bucket: String?
    /// To retrieve the checksum, this parameter must be enabled. In addition, if you enable ChecksumMode and the object is encrypted with Amazon Web Services Key Management Service (Amazon Web Services KMS), you must have permission to use the kms:Decrypt action for the request to succeed.
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
    /// The object key.
    /// This member is required.
    var key: String?
    /// Part number of the object being read. This is a positive integer between 1 and 10,000. Effectively performs a 'ranged' HEAD request for the part specified. Useful querying about the size of the part and the number of parts in this object.
    var partNumber: Int?
    /// HeadObject returns only the metadata for an object. If the Range is satisfiable, only the ContentLength is affected in the response. If the Range is not satisfiable, S3 returns a 416 - Requested Range Not Satisfiable error.
    var range: String?
    /// Confirms that the requester knows that they will be charged for the request. Bucket owners need not specify this parameter in their requests. If either the source or destination Amazon S3 bucket has Requester Pays enabled, the requester will pay for corresponding charges to copy the object. For information about downloading objects from Requester Pays buckets, see [Downloading Objects in Requester Pays Buckets](https://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html) in the Amazon S3 User Guide.
    var requestPayer: S3ClientTypes.RequestPayer?
    /// Specifies the algorithm to use to when encrypting the object (for example, AES256).
    var sseCustomerAlgorithm: String?
    /// Specifies the customer-provided encryption key for Amazon S3 to use in encrypting data. This value is used to store the object and then it is discarded; Amazon S3 does not store the encryption key. The key must be appropriate for use with the algorithm specified in the x-amz-server-side-encryption-customer-algorithm header.
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
        self.sseCustomerAlgorithm = sseCustomerAlgorithm
        self.sseCustomerKey = sseCustomerKey
        self.sseCustomerKeyMD5 = sseCustomerKeyMD5
        self.versionId = versionId
    }
}


struct HeadObjectOutputResponse: Equatable {
    /// Indicates that a range of bytes was specified.
    var acceptRanges: String?
    /// The archive state of the head object.
    var archiveStatus: S3ClientTypes.ArchiveStatus?
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
    /// Specifies whether a legal hold is in effect for this object. This header is only returned if the requester has the s3:GetObjectLegalHold permission. This header is not returned if the specified version of this object has never had a legal hold applied. For more information about S3 Object Lock, see [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html).
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    /// The Object Lock mode, if any, that's in effect for this object. This header is only returned if the requester has the s3:GetObjectRetention permission. For more information about S3 Object Lock, see [Object Lock](https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lock.html).
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    /// The date and time when the Object Lock retention period expires. This header is only returned if the requester has the s3:GetObjectRetention permission.
    var objectLockRetainUntilDate: Date?
    /// The count of parts this object has. This value is only returned if you specify partNumber in your request and the object was uploaded as a multipart upload.
    var partsCount: Int
    /// Amazon S3 can return this header if your request involves a bucket that is either a source or a destination in a replication rule. In replication, you have a source bucket on which you configure replication and destination bucket or buckets where Amazon S3 stores object replicas. When you request an object (GetObject) or object metadata (HeadObject) from these buckets, Amazon S3 will return the x-amz-replication-status header in the response as follows:
    ///
    /// * If requesting an object from the source bucket, Amazon S3 will return the x-amz-replication-status header if the object in your request is eligible for replication. For example, suppose that in your replication configuration, you specify object prefix TaxDocs requesting Amazon S3 to replicate objects with key prefix TaxDocs. Any objects you upload with this key name prefix, for example TaxDocs/document1.pdf, are eligible for replication. For any object request with this key name prefix, Amazon S3 will return the x-amz-replication-status header with value PENDING, COMPLETED or FAILED indicating object replication status.
    ///
    /// * If requesting an object from a destination bucket, Amazon S3 will return the x-amz-replication-status header with value REPLICA if the object in your request is a replica that Amazon S3 created and there is no replica modification replication in progress.
    ///
    /// * When replicating objects to multiple destination buckets, the x-amz-replication-status header acts differently. The header of the source object will only return a value of COMPLETED when replication is successful to all destinations. The header will remain at value PENDING until replication has completed for all destinations. If one or more destinations fails replication the header will return FAILED.
    ///
    ///
    /// For more information, see [Replication](https://docs.aws.amazon.com/AmazonS3/latest/dev/NotificationHowTo.html).
    var replicationStatus: S3ClientTypes.ReplicationStatus?
    /// If present, indicates that the requester was successfully charged for the request.
    var requestCharged: S3ClientTypes.RequestCharged?
    /// If the object is an archived object (an object whose storage class is GLACIER), the response includes this header if either the archive restoration is in progress (see [RestoreObject](https://docs.aws.amazon.com/AmazonS3/latest/API/API_RestoreObject.html) or an archive copy is already restored. If an archive copy is already restored, the header value indicates when Amazon S3 is scheduled to delete the object copy. For example: x-amz-restore: ongoing-request="false", expiry-date="Fri, 21 Dec 2012 00:00:00 GMT" If the object restoration is in progress, the header returns the value ongoing-request="true". For more information about archiving objects, see [Transitioning Objects: General Considerations](https://docs.aws.amazon.com/AmazonS3/latest/dev/object-lifecycle-mgmt.html#lifecycle-transition-general-considerations).
    var restore: String?
    /// The server-side encryption algorithm used when storing this object in Amazon S3 (for example, AES256, aws:kms, aws:kms:dsse).
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header confirming the encryption algorithm used.
    var sseCustomerAlgorithm: String?
    /// If server-side encryption with a customer-provided encryption key was requested, the response will include this header to provide round-trip message integrity verification of the customer-provided encryption key.
    var sseCustomerKeyMD5: String?
    /// If present, specifies the ID of the Key Management Service (KMS) symmetric encryption customer managed key that was used for the object.
    var ssekmsKeyId: String?
    /// Provides storage class information of the object. Amazon S3 returns this header for all objects except for S3 Standard storage class objects. For more information, see [Storage Classes](https://docs.aws.amazon.com/AmazonS3/latest/dev/storage-class-intro.html).
    var storageClass: S3ClientTypes.StorageClass?
    /// Version of the object.
    var versionId: String?
    /// If the bucket is configured as a website, redirects requests for this object to another object in the same bucket or to an external URL. Amazon S3 stores the value of this header in the object metadata.
    var websiteRedirectLocation: String?

    init(
        acceptRanges: String? = nil,
        archiveStatus: S3ClientTypes.ArchiveStatus? = nil,
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
        versionId: String? = nil,
        websiteRedirectLocation: String? = nil
    )
    {
        self.acceptRanges = acceptRanges
        self.archiveStatus = archiveStatus
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
        self.versionId = versionId
        self.websiteRedirectLocation = websiteRedirectLocation
    }
}


/*
 extension HeadObjectInput: HeaderProvider {
     var headers: Headers {
         var items = Headers()
         if let checksumMode = checksumMode {
             items.add(Header(name: "x-amz-checksum-mode", value: String(checksumMode.rawValue)))
         }
         if let expectedBucketOwner = expectedBucketOwner {
             items.add(Header(name: "x-amz-expected-bucket-owner", value: String(expectedBucketOwner)))
         }
         if let ifMatch = ifMatch {
             items.add(Header(name: "If-Match", value: String(ifMatch)))
         }
         if let ifModifiedSince = ifModifiedSince {
             items.add(Header(name: "If-Modified-Since", value: String(TimestampFormatter(format: .httpDate).string(from: ifModifiedSince))))
         }
         if let ifNoneMatch = ifNoneMatch {
             items.add(Header(name: "If-None-Match", value: String(ifNoneMatch)))
         }
         if let ifUnmodifiedSince = ifUnmodifiedSince {
             items.add(Header(name: "If-Unmodified-Since", value: String(TimestampFormatter(format: .httpDate).string(from: ifUnmodifiedSince))))
         }
         if let range = range {
             items.add(Header(name: "Range", value: String(range)))
         }
         if let requestPayer = requestPayer {
             items.add(Header(name: "x-amz-request-payer", value: String(requestPayer.rawValue)))
         }
         if let sseCustomerAlgorithm = sseCustomerAlgorithm {
             items.add(Header(name: "x-amz-server-side-encryption-customer-algorithm", value: String(sseCustomerAlgorithm)))
         }
         if let sseCustomerKey = sseCustomerKey {
             items.add(Header(name: "x-amz-server-side-encryption-customer-key", value: String(sseCustomerKey)))
         }
         if let sseCustomerKeyMD5 = sseCustomerKeyMD5 {
             items.add(Header(name: "x-amz-server-side-encryption-customer-key-MD5", value: String(sseCustomerKeyMD5)))
         }
         return items
     }
 }
 */

/*
 extension HeadObjectInput: QueryItemProvider {
     var queryItems: [URLQueryItem] {
         get throws {
             var items = [URLQueryItem]()
             if let versionId = versionId {
                 let versionIdQueryItem = URLQueryItem(name: "versionId".urlPercentEncoding(), value: String(versionId).urlPercentEncoding())
                 items.append(versionIdQueryItem)
             }
             if let partNumber = partNumber {
                 let partNumberQueryItem = URLQueryItem(name: "partNumber".urlPercentEncoding(), value: String(partNumber).urlPercentEncoding())
                 items.append(partNumberQueryItem)
             }
             return items
         }
     }
 }
 */

/*
 extension HeadObjectOutputResponse: HttpResponseBinding {
     init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) async throws {
         if let acceptRangesHeaderValue = httpResponse.headers.value(for: "accept-ranges") {
             self.acceptRanges = acceptRangesHeaderValue
         } else {
             self.acceptRanges = nil
         }
         if let archiveStatusHeaderValue = httpResponse.headers.value(for: "x-amz-archive-status") {
             self.archiveStatus = S3ClientTypes.ArchiveStatus(rawValue: archiveStatusHeaderValue)
         } else {
             self.archiveStatus = nil
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
     }
 }
 */
