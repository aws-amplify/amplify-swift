//
//  File.swift
//  
//
//  Created by Saultz, Ian on 10/30/23.
//

import Foundation

struct CompleteMultipartUploadInput: Equatable, Encodable {
    /// This member is required.
    var bucket: String
    /// This member is required.
    var key: String
    /// This member is required.
    var uploadId: String

    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?
    var expectedBucketOwner: String?
    var multipartUpload: S3ClientTypes.CompletedMultipartUpload?
    var requestPayer: S3ClientTypes.RequestPayer?
    var sseCustomerAlgorithm: String?
    var sseCustomerKey: String?
    var sseCustomerKeyMD5: String?

    var headers: [String: String] {
        [
            "x-amz-checksum-crc32": checksumCRC32,
            "x-amz-checksum-crc32c": checksumCRC32C,
            "x-amz-checksum-sha1": checksumSHA1,
            "x-amz-checksum-sha256": checksumSHA256,
            "x-amz-expected-bucket-owner": expectedBucketOwner,
            "x-amz-request-payer": requestPayer?.rawValue,
            "x-amz-server-side-encryption-customer-algorithm": sseCustomerAlgorithm,
            "x-amz-server-side-encryption-customer-key": sseCustomerKey,
            "x-amz-server-side-encryption-customer-key-MD5": sseCustomerKeyMD5
        ].compactMapValues { $0 }
    }

    var queryItems: [URLQueryItem] {
        [
            .init(name: "x-id", value: "CompleteMultipartUpload"),
            .init(name: "uploadId", value: uploadId.urlQueryEncoded())
        ]
            .compactMap { $0.value == nil ? nil : $0 }
    }

    var urlPath: String {
        key.urlPathEncoded()
    }

    enum CodingKeys: String, CodingKey {
        case multipartUpload = "CompleteMultipartUpload"
    }
}

struct CompleteMultipartUploadOutputResponse: Equatable, Decodable {
    var bucket: String?
    var key: String?
    var eTag: String?
    var location: String?
    var checksumCRC32: String?
    var checksumCRC32C: String?
    var checksumSHA1: String?
    var checksumSHA256: String?

    // "x-amz-server-side-encryption-bucket-key-enabled" ?? false
    var bucketKeyEnabled: Bool?
    // "x-amz-expiration"
    var expiration: String?
    // "x-amz-request-charged"
    var requestCharged: S3ClientTypes.RequestCharged?
    // "x-amz-server-side-encryption"
    var serverSideEncryption: S3ClientTypes.ServerSideEncryption?
    // "x-amz-server-side-encryption-aws-kms-key-id"
    var ssekmsKeyId: String?
    // "x-amz-version-id"
    var versionId: String?

    enum CodingKeys: String, CodingKey {
        case bucket = "Bucket"
        case checksumCRC32 = "ChecksumCRC32"
        case checksumCRC32C = "ChecksumCRC32C"
        case checksumSHA1 = "ChecksumSHA1"
        case checksumSHA256 = "ChecksumSHA256"
        case eTag = "ETag"
        case key = "Key"
        case location = "Location"
    }
}

extension CompleteMultipartUploadOutputResponse: HeadersApplying {
    func applying(headers: [String: String]) -> Self {
        var copy = self
        copy.bucketKeyEnabled = headers["x-amz-server-side-encryption-bucket-key-enabled"]
            .flatMap(Bool.init)
        copy.expiration = headers["x-amz-expiration"]
        copy.requestCharged = headers["x-amz-request-charged"]
            .flatMap(S3ClientTypes.RequestCharged.init(rawValue:))
        copy.serverSideEncryption = headers["x-amz-server-side-encryption"]
            .flatMap(S3ClientTypes.ServerSideEncryption.init(rawValue:))
        copy.ssekmsKeyId = headers["x-amz-server-side-encryption-aws-kms-key-id"]
        copy.versionId = headers["x-amz-version-id"]
        return copy
    }
}
