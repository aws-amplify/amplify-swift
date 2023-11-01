//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

/*
 "PutObject":{
   "name":"PutObject",
   "http":{
     "method":"PUT",
     "requestUri":"/{Bucket}/{Key+}"
   },
   "input":{"shape":"PutObjectRequest"},
   "output":{"shape":"PutObjectOutput"},
   "documentationUrl":"http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectPUT.html",
   "httpChecksum":{
     "requestAlgorithmMember":"ChecksumAlgorithm",
     "requestChecksumRequired":false
   }
 },
 */

extension PutObjectInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

struct PutObjectInput: Equatable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String

    var acl: S3ClientTypes.ObjectCannedACL?
    var body: Data?
    var bucketKeyEnabled: Bool?
    var cacheControl: String?
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var contentDisposition: String?
    var contentEncoding: String?
    var contentLanguage: String?
    var contentLength: Int?
    var contentMD5: String?
    var contentType: String?
    var expectedBucketOwner: String?
    var expires: Date?
    var grantFullControl: String?
    var grantRead: String?
    var grantReadACP: String?
    var grantWriteACP: String?
    var metadata: [String:String]?
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    var objectLockRetainUntilDate: Date?
    var requestPayer: S3ClientTypes.RequestPayer?
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    var sseCustomerAlgorithm: String?
    var sseCustomerKey: String?
    var sseCustomerKeyMD5: String?
    var ssekmsEncryptionContext: String?
    var ssekmsKeyId: String?
    var storageClass: S3ClientTypes.StorageClass?
    var tagging: String?
    var websiteRedirectLocation: String?

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }

    var _headers: [String: String?] {
        [
            "x-amz-acl": acl?.rawValue,
            "x-amz-server-side-encryption-bucket-key-enabled": bucketKeyEnabled.map(String.init),
            "Cache-Control": cacheControl,
            "x-amz-sdk-checksum-algorithm": checksumAlgorithm?.rawValue,
            "x-amz-checksum-crc32": checksumCRC32,
            "x-amz-checksum-crc32c": checksumCRC32C,
            "x-amz-checksum-sha1": checksumSHA1,
            "x-amz-checksum-sha256": checksumSHA256,
            "Content-Disposition": contentDisposition,
            "Content-Encoding": contentEncoding,
            "Content-Language": contentLanguage,
            "Content-Length": contentLength.map(String.init),
            "Content-MD5": contentMD5,
            "Content-Type": contentType,
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "Expires": expires.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            },
            "x-amz-grant-full-control": grantFullControl,
            "x-amz-grant-read": grantRead,
            "x-amz-grant-read-acp": grantReadACP,
            "x-amz-grant-write-acp": grantWriteACP,
            "x-amz-object-lock-legal-hold": objectLockLegalHoldStatus?.rawValue,
            "x-amz-object-lock-mode": objectLockMode?.rawValue,
            "x-amz-object-lock-retain-until-date": objectLockRetainUntilDate.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            },
            "x-amz-request-payer": requestPayer?.rawValue,
            "x-amz-server-side-encryption-customer-algorithm": sseCustomerAlgorithm,
            "x-amz-server-side-encryption-customer-key": sseCustomerKey,
            "x-amz-server-side-encryption-customer-key-MD5": sseCustomerKeyMD5,
            "x-amz-server-side-encryption-context": ssekmsEncryptionContext,
            "x-amz-server-side-encryption-aws-kms-key-id": ssekmsKeyId,
            "x-amz-server-side-encryption": serverSideEncryption?.rawValue,
            "x-amz-storage-class": storageClass?.rawValue,
            "x-amz-tagging": tagging,
            "x-amz-website-redirect-location": websiteRedirectLocation
        ]
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [.init(name: "x-id", value: "PutObject")]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}

struct PutObjectOutputResponse: Equatable {
    var bucketKeyEnabled: Bool?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var eTag: String?
    var expiration: String?
    var requestCharged: S3ClientTypes.RequestCharged?
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    var sseCustomerAlgorithm: String?
    var sseCustomerKeyMD5: String?
    var ssekmsEncryptionContext: String?
    var ssekmsKeyId: String?
    var versionId: String?

    func applying(headers: [String: String]?) -> Self {
        guard let headers else { return self }
        var copy = self
        copy.bucketKeyEnabled = headers["x-amz-server-side-encryption-bucket-key-enabled"].flatMap(Bool.init)
        copy.checksumCRC32 = headers["x-amz-checksum-crc32"]
        copy.checksumCRC32C = headers["x-amz-checksum-crc32c"]
        copy.checksumSHA1 = headers["x-amz-checksum-sha1"]
        copy.checksumSHA256 = headers["x-amz-checksum-sha256"]
        copy.eTag = headers["ETag"]
        copy.expiration = headers["x-amz-expiration"]
        copy.requestCharged = headers["x-amz-request-charged"].flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        copy.sseCustomerAlgorithm = headers["x-amz-server-side-encryption-customer-algorithm"]
        copy.sseCustomerKeyMD5 = headers["x-amz-server-side-encryption-customer-key-MD5"]
        copy.ssekmsEncryptionContext = headers["x-amz-server-side-encryption-context"]
        copy.ssekmsKeyId = headers["x-amz-server-side-encryption-aws-kms-key-id"]
        copy.serverSideEncryption = headers["x-amz-server-side-encryption"].flatMap(S3ClientTypes.ServerSideEncryption.init(rawValue:))
        copy.versionId = headers["x-amz-version-id"]
        return copy
    }
}

/*
 "PutObjectRequest":{
       "type":"structure",
       "required":[
         "Bucket",
         "Key"
       ],
       "members":{
         "ACL":{
           "shape":"ObjectCannedACL",
           "location":"header",
           "locationName":"x-amz-acl"
         },
         "Body":{
           "shape":"Body",
           "streaming":true
         },
         "Bucket":{
           "shape":"BucketName",
           "contextParam":{"name":"Bucket"},
           "location":"uri",
           "locationName":"Bucket"
         },
         "CacheControl":{
           "shape":"CacheControl",
           "location":"header",
           "locationName":"Cache-Control"
         },
         "ContentDisposition":{
           "shape":"ContentDisposition",
           "location":"header",
           "locationName":"Content-Disposition"
         },
         "ContentEncoding":{
           "shape":"ContentEncoding",
           "location":"header",
           "locationName":"Content-Encoding"
         },
         "ContentLanguage":{
           "shape":"ContentLanguage",
           "location":"header",
           "locationName":"Content-Language"
         },
         "ContentLength":{
           "shape":"ContentLength",
           "location":"header",
           "locationName":"Content-Length"
         },
         "ContentMD5":{
           "shape":"ContentMD5",
           "location":"header",
           "locationName":"Content-MD5"
         },
         "ContentType":{
           "shape":"ContentType",
           "location":"header",
           "locationName":"Content-Type"
         },
         "ChecksumAlgorithm":{
           "shape":"ChecksumAlgorithm",
           "location":"header",
           "locationName":"x-amz-sdk-checksum-algorithm"
         },
         "ChecksumCRC32":{
           "shape":"ChecksumCRC32",
           "location":"header",
           "locationName":"x-amz-checksum-crc32"
         },
         "ChecksumCRC32C":{
           "shape":"ChecksumCRC32C",
           "location":"header",
           "locationName":"x-amz-checksum-crc32c"
         },
         "ChecksumSHA1":{
           "shape":"ChecksumSHA1",
           "location":"header",
           "locationName":"x-amz-checksum-sha1"
         },
         "ChecksumSHA256":{
           "shape":"ChecksumSHA256",
           "location":"header",
           "locationName":"x-amz-checksum-sha256"
         },
         "Expires":{
           "shape":"Expires",
           "location":"header",
           "locationName":"Expires"
         },
         "GrantFullControl":{
           "shape":"GrantFullControl",
           "location":"header",
           "locationName":"x-amz-grant-full-control"
         },
         "GrantRead":{
           "shape":"GrantRead",
           "location":"header",
           "locationName":"x-amz-grant-read"
         },
         "GrantReadACP":{
           "shape":"GrantReadACP",
           "location":"header",
           "locationName":"x-amz-grant-read-acp"
         },
         "GrantWriteACP":{
           "shape":"GrantWriteACP",
           "location":"header",
           "locationName":"x-amz-grant-write-acp"
         },
         "Key":{
           "shape":"ObjectKey",
           "location":"uri",
           "locationName":"Key"
         },
         "Metadata":{
           "shape":"Metadata",
           "location":"headers",
           "locationName":"x-amz-meta-"
         },
         "ServerSideEncryption":{
           "shape":"ServerSideEncryption",
           "location":"header",
           "locationName":"x-amz-server-side-encryption"
         },
         "StorageClass":{
           "shape":"StorageClass",
           "location":"header",
           "locationName":"x-amz-storage-class"
         },
         "WebsiteRedirectLocation":{
           "shape":"WebsiteRedirectLocation",
           "location":"header",
           "locationName":"x-amz-website-redirect-location"
         },
         "SSECustomerAlgorithm":{
           "shape":"SSECustomerAlgorithm",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-customer-algorithm"
         },
         "SSECustomerKey":{
           "shape":"SSECustomerKey",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-customer-key"
         },
         "SSECustomerKeyMD5":{
           "shape":"SSECustomerKeyMD5",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-customer-key-MD5"
         },
         "SSEKMSKeyId":{
           "shape":"SSEKMSKeyId",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-aws-kms-key-id"
         },
         "SSEKMSEncryptionContext":{
           "shape":"SSEKMSEncryptionContext",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-context"
         },
         "BucketKeyEnabled":{
           "shape":"BucketKeyEnabled",
           "location":"header",
           "locationName":"x-amz-server-side-encryption-bucket-key-enabled"
         },
         "RequestPayer":{
           "shape":"RequestPayer",
           "location":"header",
           "locationName":"x-amz-request-payer"
         },
         "Tagging":{
           "shape":"TaggingHeader",
           "location":"header",
           "locationName":"x-amz-tagging"
         },
         "ObjectLockMode":{
           "shape":"ObjectLockMode",
           "location":"header",
           "locationName":"x-amz-object-lock-mode"
         },
         "ObjectLockRetainUntilDate":{
           "shape":"ObjectLockRetainUntilDate",
           "location":"header",
           "locationName":"x-amz-object-lock-retain-until-date"
         },
         "ObjectLockLegalHoldStatus":{
           "shape":"ObjectLockLegalHoldStatus",
           "location":"header",
           "locationName":"x-amz-object-lock-legal-hold"
         },
         "ExpectedBucketOwner":{
           "shape":"AccountId",
           "location":"header",
           "locationName":"x-amz-expected-bucket-owner"
         }
       },
       "payload":"Body"
     },
 */
