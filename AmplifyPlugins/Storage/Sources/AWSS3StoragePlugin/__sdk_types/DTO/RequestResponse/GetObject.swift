//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation
import AWSPluginsCore

extension GetObjectInput {
    func presignURL(config: S3ClientConfiguration, expiration: Double) async throws -> URLRequest {
        let credentialsProvider = config.credentialsProvider
        let credentials = try await credentialsProvider.fetchCredentials()

        let signer = SigV4Signer(
            credentials: credentials,
            serviceName: "s3",
            region: config.region
        )

        // TODO: Add user agent header
        let request = signer.sign(
            url: .init(string: "")!,
            method: .get,
            headers: headers,
            expires: Int(expiration)
        )

        fatalError()
    }

    func presignURL(config: S3ClientConfiguration, expiration: Double) throws -> URL {
        fatalError()
    }
}

/*
 "GetObjectRequest":{
   "type":"structure",
   "required":[
     "Bucket",
     "Key"
   ],
   "members":{
     "Bucket":{
       "shape":"BucketName",
       "contextParam":{"name":"Bucket"},
       "location":"uri",
       "locationName":"Bucket"
     },
     "IfMatch":{
       "shape":"IfMatch",
       "location":"header",
       "locationName":"If-Match"
     },
     "IfModifiedSince":{
       "shape":"IfModifiedSince",
       "location":"header",
       "locationName":"If-Modified-Since"
     },
     "IfNoneMatch":{
       "shape":"IfNoneMatch",
       "location":"header",
       "locationName":"If-None-Match"
     },
     "IfUnmodifiedSince":{
       "shape":"IfUnmodifiedSince",
       "location":"header",
       "locationName":"If-Unmodified-Since"
     },
     "Key":{
       "shape":"ObjectKey",
       "location":"uri",
       "locationName":"Key"
     },
     "Range":{
       "shape":"Range",
       "location":"header",
       "locationName":"Range"
     },
     "ResponseCacheControl":{
       "shape":"ResponseCacheControl",
       "location":"querystring",
       "locationName":"response-cache-control"
     },
     "ResponseContentDisposition":{
       "shape":"ResponseContentDisposition",
       "location":"querystring",
       "locationName":"response-content-disposition"
     },
     "ResponseContentEncoding":{
       "shape":"ResponseContentEncoding",
       "location":"querystring",
       "locationName":"response-content-encoding"
     },
     "ResponseContentLanguage":{
       "shape":"ResponseContentLanguage",
       "location":"querystring",
       "locationName":"response-content-language"
     },
     "ResponseContentType":{
       "shape":"ResponseContentType",
       "location":"querystring",
       "locationName":"response-content-type"
     },
     "ResponseExpires":{
       "shape":"ResponseExpires",
       "location":"querystring",
       "locationName":"response-expires"
     },
     "VersionId":{
       "shape":"ObjectVersionId",
       "location":"querystring",
       "locationName":"versionId"
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
     "RequestPayer":{
       "shape":"RequestPayer",
       "location":"header",
       "locationName":"x-amz-request-payer"
     },
     "PartNumber":{
       "shape":"PartNumber",
       "location":"querystring",
       "locationName":"partNumber"
     },
     "ExpectedBucketOwner":{
       "shape":"AccountId",
       "location":"header",
       "locationName":"x-amz-expected-bucket-owner"
     },
     "ChecksumMode":{
       "shape":"ChecksumMode",
       "location":"header",
       "locationName":"x-amz-checksum-mode"
     }
   }
 },
 */

extension String {
    static let allowedForQuery = CharacterSet.alphanumerics.union(
        .init(charactersIn: "_-.~")
    )

    func urlQueryEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: Self.allowedForQuery) ?? self
    }

    static let allowedForPath = CharacterSet.alphanumerics.union(
        .init(charactersIn: "/_-.~")
    )

    func urlPathEncoded() -> String {
        addingPercentEncoding(withAllowedCharacters: Self.allowedForPath) ?? self
    }
}

struct GetObjectInput: Equatable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String

    var checksumMode: S3ClientTypes.ChecksumMode?
    var expectedBucketOwner: String?
    var ifMatch: String?
    var ifModifiedSince: Date?
    var ifNoneMatch: String?
    var ifUnmodifiedSince: Date?
    var partNumber: Int?
    var range: String?
    var requestPayer: S3ClientTypes.RequestPayer?
    var responseCacheControl: String?
    var responseContentDisposition: String?
    var responseContentEncoding: String?
    var responseContentLanguage: String?
    var responseContentType: String?
    var responseExpires: Date?
    var sseCustomerAlgorithm: String?
    var sseCustomerKey: String?
    var sseCustomerKeyMD5: String?
    var versionId: String?

    var _headers: [String: String?] {
        [
            "x-amz-checksum-mode": checksumMode?.rawValue,
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "If-Match": ifMatch,
            "If-Modified-Since": ifModifiedSince.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            },
            "If-None-Match": ifNoneMatch,
            "If-Unmodified-Since": ifUnmodifiedSince.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            },
            "Range": range,
            "x-amz-request-payer": requestPayer?.rawValue,
            "x-amz-server-side-encryption-customer-algorithm": sseCustomerAlgorithm,
            "x-amz-server-side-encryption-customer-key": sseCustomerKey,
            "x-amz-server-side-encryption-customer-key-MD5": sseCustomerKeyMD5
        ]
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        let responseExpires = URLQueryItem(
            name: "response-expires".urlQueryEncoded(),
            value: responseExpires.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            }?.urlQueryEncoded()
        )
        return [
            .init(name: "x-id", value: "GetObject"),
            .init(name: "versionId".urlQueryEncoded(), value: versionId?.urlQueryEncoded()),
            .init(name: "response-content-disposition".urlQueryEncoded(), value: responseContentDisposition?.urlQueryEncoded()),
            .init(name: "partNumber".urlQueryEncoded(), value: partNumber.map(String.init)?.urlQueryEncoded()),
            .init(name: "response-content-type".urlQueryEncoded(), value: responseContentType?.urlQueryEncoded()),
            .init(name: "response-content-encoding".urlQueryEncoded(), value: responseContentEncoding?.urlQueryEncoded()),
            .init(name: "response-cache-control".urlQueryEncoded(), value: responseCacheControl?.urlQueryEncoded()),
            .init(name: "response-content-language".urlQueryEncoded(), value: responseContentLanguage?.urlQueryEncoded()),
        ] + [responseExpires]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}



struct GetObjectOutputResponse: Equatable {
    /// Indicates that a range of bytes was specified.
    var acceptRanges: String?
    /// Object data.
    var body: Data?
    var bucketKeyEnabled: Bool?
    var cacheControl: String?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var contentDisposition: String?
    var contentEncoding: String?
    var contentLanguage: String?
    var contentLength: Int?
    var contentRange: String?
    var contentType: String?
    var deleteMarker: Bool?
    var eTag: String?
    var expiration: String?
    var expires: String?
    var lastModified: Date?
    var metadata: [String:String]?
    var missingMeta: Int?
    var objectLockLegalHoldStatus: S3ClientTypes.ObjectLockLegalHoldStatus?
    var objectLockMode: S3ClientTypes.ObjectLockMode?
    var objectLockRetainUntilDate: Date?
    var partsCount: Int?
    var replicationStatus: S3ClientTypes.ReplicationStatus?
    var requestCharged: S3ClientTypes.RequestCharged?
    var restore: String?
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    var sseCustomerAlgorithm: String?
    var sseCustomerKeyMD5: String?
    var ssekmsKeyId: String?
    var storageClass: S3ClientTypes.StorageClass?
    var tagCount: Int?
    var versionId: String?
    var websiteRedirectLocation: String?

    enum CodingKeys: String, CodingKey {
        case body = "Body"
    }

    func applying(headers: [String: String]?) -> Self {
        guard let headers else { return self }
        var copy = self
        copy.acceptRanges = headers["accept-ranges"]
        copy.bucketKeyEnabled = headers["x-amz-server-side-encryption-bucket-key-enabled"]
            .flatMap(Bool.init)
        copy.cacheControl = headers["Cache-Control"]
        copy.checksumCRC32 = headers["x-amz-checksum-crc32"]
        copy.checksumCRC32C = headers["x-amz-checksum-crc32c"]
        copy.checksumSHA1 = headers["x-amz-checksum-sha1"]
        copy.checksumSHA256 = headers["x-amz-checksum-sha256"]
        copy.contentDisposition = headers["Content-Disposition"]
        copy.contentEncoding = headers["Content-Encoding"]
        copy.contentLanguage = headers["Content-Language"]
        copy.contentLength = headers["Content-Length"]
            .flatMap(Int.init)
        copy.contentRange = headers["Content-Range"]
        copy.contentType = headers["Content-Type"]
        copy.deleteMarker = headers["x-amz-delete-marker"]
            .flatMap(Bool.init)
        copy.eTag = headers["ETag"]
        copy.expiration = headers["x-amz-expiration"]
        copy.expires = headers["Expires"]
        copy.lastModified = headers["Last-Modified"].flatMap {
            DateFormatting().date(from: $0, formatter: .rfc5322WithFractionalSeconds)
        }
        copy.missingMeta = headers["x-amz-missing-meta"]
            .flatMap(Int.init)
        copy.objectLockLegalHoldStatus = headers["x-amz-object-lock-legal-hold"]
            .flatMap(S3ClientTypes.ObjectLockLegalHoldStatus.init(rawValue:))
        copy.objectLockMode = headers["x-amz-object-lock-mode"]
            .flatMap(S3ClientTypes.ObjectLockMode.init(rawValue:))
        copy.objectLockRetainUntilDate = headers["x-amz-object-lock-retain-until-date"].flatMap {
            DateFormatting().date(from: $0, formatter: .rfc5322WithFractionalSeconds)
        }
        copy.partsCount = headers["x-amz-mp-parts-count"]
            .flatMap(Int.init)
        copy.replicationStatus = headers["x-amz-replication-status"]
            .flatMap(S3ClientTypes.ReplicationStatus.init(rawValue:))
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        copy.restore = headers["x-amz-restore"]
        copy.sseCustomerAlgorithm = headers["x-amz-server-side-encryption-customer-algorithm"]
        copy.sseCustomerKeyMD5 = headers["x-amz-server-side-encryption-customer-key-MD5"]
        copy.ssekmsKeyId = headers["x-amz-server-side-encryption-aws-kms-key-id"]
        copy.serverSideEncryption = headers["x-amz-server-side-encryption"]
            .flatMap(S3ClientTypes.ServerSideEncryption.init(rawValue:))
        copy.storageClass = headers["x-amz-storage-class"]
            .flatMap(S3ClientTypes.StorageClass.init(rawValue:))
        copy.tagCount = headers["x-amz-tagging-count"]
            .flatMap(Int.init)
        copy.versionId = headers["x-amz-version-id"]
        copy.websiteRedirectLocation = headers["x-amz-website-redirect-location"]

        copy.metadata = .init(
            uniqueKeysWithValues: headers.filter { key, _ in
                key.starts(with: "x-amz-meta-")
            }.map { key, value in
                (key.removingPrefix("x-amz-meta-"), value)
            }
        )

        return copy
    }
}

extension String {
    func removingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}


/*
 "GetObjectOutput":{
    "type":"structure",
    "members":{
      "Body":{
        "shape":"Body",
        "streaming":true
      },
      "DeleteMarker":{
        "shape":"DeleteMarker",
        "location":"header",
        "locationName":"x-amz-delete-marker"
      },
      "AcceptRanges":{
        "shape":"AcceptRanges",
        "location":"header",
        "locationName":"accept-ranges"
      },
      "Expiration":{
        "shape":"Expiration",
        "location":"header",
        "locationName":"x-amz-expiration"
      },
      "Restore":{
        "shape":"Restore",
        "location":"header",
        "locationName":"x-amz-restore"
      },
      "LastModified":{
        "shape":"LastModified",
        "location":"header",
        "locationName":"Last-Modified"
      },
      "ContentLength":{
        "shape":"ContentLength",
        "location":"header",
        "locationName":"Content-Length"
      },
      "ETag":{
        "shape":"ETag",
        "location":"header",
        "locationName":"ETag"
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
      "MissingMeta":{
        "shape":"MissingMeta",
        "location":"header",
        "locationName":"x-amz-missing-meta"
      },
      "VersionId":{
        "shape":"ObjectVersionId",
        "location":"header",
        "locationName":"x-amz-version-id"
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
      "ContentRange":{
        "shape":"ContentRange",
        "location":"header",
        "locationName":"Content-Range"
      },
      "ContentType":{
        "shape":"ContentType",
        "location":"header",
        "locationName":"Content-Type"
      },
      "Expires":{
        "shape":"Expires",
        "location":"header",
        "locationName":"Expires"
      },
      "WebsiteRedirectLocation":{
        "shape":"WebsiteRedirectLocation",
        "location":"header",
        "locationName":"x-amz-website-redirect-location"
      },
      "ServerSideEncryption":{
        "shape":"ServerSideEncryption",
        "location":"header",
        "locationName":"x-amz-server-side-encryption"
      },
      "Metadata":{
        "shape":"Metadata",
        "location":"headers",
        "locationName":"x-amz-meta-"
      },
      "SSECustomerAlgorithm":{
        "shape":"SSECustomerAlgorithm",
        "location":"header",
        "locationName":"x-amz-server-side-encryption-customer-algorithm"
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
      "BucketKeyEnabled":{
        "shape":"BucketKeyEnabled",
        "location":"header",
        "locationName":"x-amz-server-side-encryption-bucket-key-enabled"
      },
      "StorageClass":{
        "shape":"StorageClass",
        "location":"header",
        "locationName":"x-amz-storage-class"
      },
      "RequestCharged":{
        "shape":"RequestCharged",
        "location":"header",
        "locationName":"x-amz-request-charged"
      },
      "ReplicationStatus":{
        "shape":"ReplicationStatus",
        "location":"header",
        "locationName":"x-amz-replication-status"
      },
      "PartsCount":{
        "shape":"PartsCount",
        "location":"header",
        "locationName":"x-amz-mp-parts-count"
      },
      "TagCount":{
        "shape":"TagCount",
        "location":"header",
        "locationName":"x-amz-tagging-count"
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
      }
    },
    "payload":"Body"
  },
 */
