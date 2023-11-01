//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation


struct CreateMultipartUploadInput: Equatable, Encodable {
    /// This member is required.
    var key: String
    /// This member is required.
    var bucket: String

    var acl: S3ClientTypes.ObjectCannedACL?
    var bucketKeyEnabled: Bool?
    var cacheControl: String?
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    var contentDisposition: String?
    var contentEncoding: String?
    var contentLanguage: String?
    var contentType: String?
    var expectedBucketOwner: String?
    var expires: Date?
    var grantFullControl: String?
    var grantRead: String?
    var grantReadACP: String?
    var grantWriteACP: String?
    var metadata: [String: String]?
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
    /// The tag-set for the object. The tag-set must be encoded as URL Query parameters.
    var tagging: String?
    var websiteRedirectLocation: String?

    var _headers: [String: String?] {
        [
            "x-amz-acl": acl?.rawValue,
            "x-amz-server-side-encryption-bucket-key-enabled": bucketKeyEnabled.map(String.init),
            "Cache-Control": cacheControl,
            "x-amz-checksum-algorithm": checksumAlgorithm?.rawValue,
            "Content-Disposition": contentEncoding,
            "Content-Language": contentLanguage,
            "Content-Type": contentType,
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "Expires": expires.map {
                DateFormatting().string(from: $0, formatter: .rfc5322WithFractionalSeconds)
            },
            "x-amz-grant-full-control": grantFullControl,
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
        ].merging(
            metadata?.map { ("x-amz-meta-\($0.key)", $0.value) } ?? [],
            uniquingKeysWith: { current, _ in current }
        )
    }

    var headers: [String: String] {
        _headers.compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "uploads", value: nil),
            .init(name: "x-id", value: "CreateMultipartUpload")
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }
}

struct CreateMultipartUploadOutputResponse: Equatable, Decodable {
    var abortDate: Date?
    var abortRuleId: String?
    var bucket: String?
    var bucketKeyEnabled: Bool?
    var checksumAlgorithm: S3ClientTypes.ChecksumAlgorithm?
    var key: String?
    var requestCharged: S3ClientTypes.RequestCharged?
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    var sseCustomerAlgorithm: String?
    var sseCustomerKeyMD5: String?
    var ssekmsEncryptionContext: String?
    var ssekmsKeyId: String?
    var uploadId: String?

    enum CodingKeys: String, CodingKey {
        case bucket = "Bucket"
        case key = "Key"
        case uploadId = "UploadId"
    }

    func applying(headers: [String: String]?) -> Self {
        guard let headers else { return self }
        var copy = self
        copy.abortDate = headers["x-amz-abort-date"].flatMap {
            DateFormatting().date(from: $0, formatter: .rfc5322WithFractionalSeconds)
        }
        copy.abortRuleId = headers["x-amz-abort-rule-id"]
        copy.bucketKeyEnabled = headers["x-amz-server-side-encryption-bucket-key-enabled"]
            .flatMap(Bool.init(_:))
        copy.checksumAlgorithm = headers["x-amz-checksum-algorithm"]
            .flatMap(S3ClientTypes.ChecksumAlgorithm.init(rawValue:))
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        copy.sseCustomerAlgorithm = headers["x-amz-server-side-encryption-customer-algorithm"]
        copy.sseCustomerKeyMD5 = headers["x-amz-server-side-encryption-customer-key-MD5"]
        copy.ssekmsEncryptionContext = headers["x-amz-server-side-encryption-context"]
        copy.ssekmsKeyId = headers["x-amz-server-side-encryption-aws-kms-key-id"]
        copy.serverSideEncryption = headers["x-amz-server-side-encryption"]
            .flatMap(S3ClientTypes.ServerSideEncryption.init(rawValue:))

        return copy
    }
}
