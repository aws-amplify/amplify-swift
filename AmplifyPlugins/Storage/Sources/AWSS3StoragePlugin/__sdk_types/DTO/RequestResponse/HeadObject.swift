//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct HeadObjectInput: Equatable, Encodable {
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

    var queryItems: [URLQueryItem] {
        [
            .init(name: "versionId", value: versionId?.urlQueryEncoded()),
            .init(
                name: "partNumber",
                value: partNumber.map(String.init)?.urlQueryEncoded()
            )
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}


struct HeadObjectOutputResponse: Equatable, Decodable {
    var acceptRanges: String?
    var archiveStatus: S3ClientTypes.ArchiveStatus?
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
    var versionId: String?
    var websiteRedirectLocation: String?

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
        copy.objectLockRetainUntilDate = headers["x-amz-object-lock-retain-until-date"]
            .flatMap {
                DateFormatting().date(from: $0, formatter: .iso8601DateFormatterWithFractionalSeconds)
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
